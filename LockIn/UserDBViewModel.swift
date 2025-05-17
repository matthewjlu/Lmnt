//
//  UserDBViewModel.swift
//  LockIn
//
//  Created by Matthew Lu on 5/16/25.
//

// AppDelegate.swift

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import Foundation

class UserDBViewModel: ObservableObject {
    //setting ref to be of type DatabaseReference
    private let ref: DatabaseReference
    
    init(userId: String) {
        ref = Database.database()
            .reference()
            .child("users")
            .child(userId)
    }
    
    func writeUserData(email: String) {
        
        let data: [String: Any] = [
                    "name": "",
                    "email": email,
                    "joinedAt": ServerValue.timestamp(),
                    "lastLogin": ""
                ]
                ref.setValue(data) { error, _ in
                    if let error = error {
                        print("❌ Error writing user profile:", error.localizedDescription)
                    } else {
                        print("✅ User profile created/updated")
                    }
                }
        readableDateTime(field: "joinedAt")
    }
    
    func updateLastLogin() {
        ref.updateChildValues(["lastLogin": ServerValue.timestamp()])
        readableDateTime(field: "lastLogin")
    }
    
    func readableDateTime(field:String) {
        ref.getData { error, snapshot in
            if let error = error {
                print("Error fetching user:", error.localizedDescription)
                return
            }
            
            guard let dict = snapshot?.value as? [String:Any], let time = dict[field] as? TimeInterval else {
                print("No field found!")
                return
            }
            
            let date = Date(timeIntervalSince1970: time / 1000)
            
            //just to make the times people joined readable
            let readable = date.formatted(
                Date.FormatStyle()
                    .month(.abbreviated)
                    .day(.twoDigits)
                    .year(.defaultDigits)
                    .hour(.defaultDigits(amPM: .abbreviated))
                    .minute(.twoDigits)
                    .second(.twoDigits)
            )
            self.ref.updateChildValues([field: readable])
        }
    }
}
    
