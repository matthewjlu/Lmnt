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

    // 1) create /parties/{autoID}
    // 2) seed with [email]
    // 3) write partyCode back to /users/{userId}
    func createParty(userId: String, email: String) async throws -> String {
        // creates new document with random ID
        let newPartyRef = partiesCol.document()
        // pulls out the auto-generated ID
        let partyId = newPartyRef.documentID

        // write initial members array
        try await newPartyRef.setData(["members": [email]])
        // update the user's partyCode (merge so we don't clobber other fields)
        try await db
            .collection("users")
            .document(userId)
            .setData(["partyCode": partyId], merge: true)

        return partyId
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

    // flip wantsToLeave = true under /parties/{partyId}/leaveRequests/{userId}
    func requestLeave(partyId: String, userId: String) async throws {
      let requestRef = partiesCol
          .document(partyId)
          .collection("leaveRequests")
          .document(userId)

      try await requestRef.setData([
        "requestedAt": FieldValue.serverTimestamp()
      ])
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
}

