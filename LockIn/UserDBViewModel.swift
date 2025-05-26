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
        self.db = Firestore.firestore()
        //gets a pointer to users/{userId}
        self.userRef = db.collection("users").document(userId)
    }

    //first time when a user signs up
    func writeUserData(email: String) {
        let data: [String: Any] = [
            "name": "",
            "email": email,
            "joinedAt": FieldValue.serverTimestamp(),
            "lastLogin": "",
            //shorthand for the type Array<String>
            "friends": [String](),
            "partyCode": ""
        ]

        userRef.setData(data) { error in
            if let error = error {
                print("Error writing user profile:", error.localizedDescription)
            } else {
                print("User profile created/updated")
                //now convert the timestamp to a readable string
                self.readableDateTime(field: "joinedAt")
            }
        }
    }

    //update just the lastLogin field
    func updateLastLogin() {
        userRef.updateData([
            "lastLogin": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating lastLogin:", error.localizedDescription)
            } else {
                print("lastLogin timestamp set")
                self.readableDateTime(field: "lastLogin")
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
