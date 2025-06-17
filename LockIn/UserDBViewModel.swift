//  UserDBViewModel.swift
//  LockIn
//
//  Created by Matthew Lu on 5/16/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class UserDBViewModel: ObservableObject {
    //database variable
    private let db: Firestore
    //doc reference pointer
    private let userRef: DocumentReference

    init(userId: String) {
        //initializing the database
        db = Firestore.firestore()
        //gets a pointer to users/{userId}
        userRef = db.collection("users").document(userId)
    }

    //first time when a user signs up
    func writeUserData(email: String) async throws -> String{
        let data: [String: Any] = [
            "name": "",
            "email": email,
            "joinedAt": FieldValue.serverTimestamp(),
            "lastLogin": FieldValue.serverTimestamp(),
            "partyCode": "",
            "friendCode": "",
            //shorthand for the type Array<String>
            "friends": [String](),
            "friendRequests": [String](),
            "partyRequests": [String: String](),
            "hoursLockedIn": 0
        ]
        
        try await self.userRef.setData(data)
        
        var listener: ListenerRegistration?
        
        listener = userRef.addSnapshotListener { snapshot, error in
            guard let snap = snapshot, error == nil else {
                print("Error listening for changes:", error!.localizedDescription)
                return
            }
            if !snap.metadata.hasPendingWrites {
                print("Pending writes cleared, now reading real timestamp.")
                self.readableDateTime(field: "joinedAt")
                self.readableDateTime(field: "lastLogin")
                listener!.remove()
                }
            }
        try await self.reserveFriendCode()
        
        return "Works!"
    }
    func randomString(length: Int) -> String {
        let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijlkmnopqrstuvwxyz0123456789")
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
    
    func reserveFriendCode() async throws {
        var code: String
        var snapshot: QuerySnapshot

        repeat {
            code = randomString(length: 5)
            snapshot = try await db
                        .collection("users")
                        .whereField("friendCode", isEqualTo: code)
                        .limit(to: 1)
                        .getDocuments()
        } while !snapshot.documents.isEmpty
        
        try await userRef
            .setData(["friendCode": code], merge: true)
    }

    //update just the lastLogin field
    func updateLastLogin() {
        userRef.updateData([
            "lastLogin": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating lastLogin:", error.localizedDescription)
            } else {
                print("lastLogin timestamp sent")
            }
            
        var listener: ListenerRegistration?
            
        listener = self.userRef.addSnapshotListener { snapshot, error in
            guard let snap = snapshot, error == nil else {
                print("Error listening for changes:", error!.localizedDescription)
                return
            }
            if !snap.metadata.hasPendingWrites {
                print("Pending writes cleared, now reading real timestamp.")
                self.readableDateTime(field: "lastLogin")
                listener!.remove()
                }
            }
        }
    }

    //Fetch the raw Timestamp for `field`, format it, and write the string back
    private func readableDateTime(field: String) {
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user document:", error.localizedDescription)
                return
            }
            guard let data = snapshot?.data(),
                    let ts = data[field] as? Timestamp else {
                print("No `\(field)` timestamp found to format")
                return
            }
            
            let date = ts.dateValue()
            let readable = date.formatted(
                Date.FormatStyle()
                    .month(.abbreviated)
                    .day(.twoDigits)
                    .year(.defaultDigits)
                    .hour(.defaultDigits(amPM: .abbreviated))
                    .minute(.twoDigits)
                    .second(.twoDigits)
            )

            self.userRef.updateData([field: readable]) { error in
                if let error = error {
                    print("Error writing formatted \(field):", error.localizedDescription)
                } else {
                    print("\(field) updated to readable string: \(readable)")
                }
            }
        }
    }
}
