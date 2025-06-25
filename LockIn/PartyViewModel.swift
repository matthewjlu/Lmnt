//
//  PartyViewModel.swift
//  LockIn
//
//
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@MainActor
class PartyViewModel: ObservableObject {
    private let db = Firestore.firestore()
    private let partiesCol: CollectionReference

    init() {
        // /parties
        partiesCol = db.collection("parties")
    }

    func randomString(length: Int) -> String {
        let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijlkmnopqrstuvwxyz0123456789")
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
    
    // 1) create /parties/{partyCode}
    // 2) seed with [email]
    // 3) write partyCode back to /users/{userId}
    func createParty(userId: String, email: String) async throws -> String {
        var code: String
        var snapshot: QuerySnapshot
        var userSnapshot: DocumentSnapshot
        
        //error checking to see if user already has partyCode
        userSnapshot = try await db
                    .collection("users")
                    .document(userId)
                    .getDocument()
        //another error check to see if user is already in another party
        snapshot = try await db
                    .collection("parties")
                    .whereField("members", arrayContains: email)
                    .limit(to: 1)
                    .getDocuments()
        
        if userSnapshot.data()?["partyCode"] as! String != "" || !snapshot.documents.isEmpty{
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "You can only have one party!"])
        }
        
        repeat {
            code = randomString(length: 10)
            snapshot = try await db
                        .collection("users")
                        .whereField("partyCode", isEqualTo: code)
                        .limit(to: 1)
                        .getDocuments()
        } while !snapshot.documents.isEmpty
        
        let newPartyRef = partiesCol.document(code)
        // write initial members array
        try await newPartyRef.setData([
            "members": [email],
            "leader": email,
            "ready": [],
            "active":false])
        // update the user's partyCode (merge so we don't clobber other fields)
        try await db
            .collection("users")
            .document(userId)
            .setData(["partyCode": code], merge: true)

        return code
    }

    // 1) fetch users/{userId}.partyCode
    // 2) fetch parties/{code}.members
    // 3) append + write back
    @discardableResult
    func joinParty(userId: String, email: String) async throws -> String {
        let userSnap = try await db
            .collection("users")
            .document(userId)
            .getDocument()

        guard
            let code = userSnap.data()?["partyCode"] as? String,
            !code.isEmpty
        else {
            return "ERROR! No party code found."
        }
        
        //gets reference to /parties/{code}
        let partyRef = partiesCol.document(code)
        //get a snapshot of the members in the party
        let partySnap = try await partyRef.getDocument()

        guard
            //if the data isn't nil, it will execute the index and then type it
            var members = partySnap.data()?["members"] as? [String]
        else {
            return "ERROR! No members array found."
        }

        members.append(email)
        //merge makes it so that setData only changes the memebers field
        try await partyRef.setData(["members": members], merge: true)

        return "SUCCESS!"
    }
    
    // flip wantsToJoin = true under /parties/{partyId}/joinRequests/{userId}
    func requestJoin(partyId: String, userId: String) async throws {
        let requestRef = partiesCol
            .document(partyId)
            .collection("joinRequests")
            .document(userId)

        try await requestRef.setData([
          "requestedAt": FieldValue.serverTimestamp()
        ])
    }
    
    @MainActor
    func readyUp(partyId: String, email: String) async throws {
      let snapshot = partiesCol
        .document(partyId)
        
      try await snapshot.setData([
        "ready": FieldValue.arrayUnion([email])
      ], merge: true)
    }
    
    func checkLeader(partyId: String, email: String) async -> Bool{
        do {
            let snapshot = try await partiesCol
              .document(partyId)
              .getDocument()
            
            if snapshot["leader"] as! String == email {
                return true
            }
        } catch {
        }
        return false
    }
    
    func clearReady(partyId: String) async throws{
        let snapshot = partiesCol
          .document(partyId)
        
        try await snapshot.setData(["ready": []], merge: true)
    }
    
    func blockActive(partyId: String) async throws {
        let snapshot = partiesCol
          .document(partyId)
        
        try await snapshot.setData(["active": true], merge: true)
    }
    
    func blockDeactive(partyId: String) async throws {
        let snapshot = partiesCol
          .document(partyId)
        
        try await snapshot.setData(["active": false], merge: true)
    }
}

