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
        //user data will be stored at /users/{userId}
        ref = Database.database()
            .reference()
            .child("users")
            .child(userId)
    }
    
    //basically this is the first write to the database when the user signs up for the site
    func writeUserData(email: String) {
        //creating the dictionary for the database
        let data: [String: Any] = [
                    "name": "",
                    "email": email,
                    "joinedAt": ServerValue.timestamp(),
                    "lastLogin": "",
                    "friends": []
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
    
    //keeping track of when the user last logged in
    func updateLastLogin() {
        ref.updateChildValues(["lastLogin": ServerValue.timestamp()])
        readableDateTime(field: "lastLogin")
    }
    
    //function for converting ServerValue.timestamp() into human readable times
    func readableDateTime(field:String) {
        //first trying to fetch the data in the database
        //snapshot is basically a picture of how the database looks when you getData
        ref.getData { error, snapshot in
            if let error = error {
                print("Error fetching user:", error.localizedDescription)
                return
            }
            
            //getting the specific key and value in the databse
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
            //updating the field in the databse
            self.ref.updateChildValues([field: readable])
        }
    }
}
    
