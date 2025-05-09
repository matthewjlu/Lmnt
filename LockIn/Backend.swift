// AppDelegate.swift

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import Foundation

class PartyViewModel: ObservableObject {
  private let ref: DatabaseReference

  init(partyId: String, userId: String) {
    ref = Database.database()
      .reference()
      .child("parties")
      .child(partyId)
      .child("members")
      .child(userId)
  }

  func requestLeave() {
    ref.child("wantsToLeave").setValue(true)
      print("LEAVE")
  }
    
 func requestJoin() {
        ref.child("wantsToJoin").setValue(true)
        print("JOIN")
 }
}

