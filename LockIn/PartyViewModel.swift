// AppDelegate.swift

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import Foundation

class PartyViewModel: ObservableObject {
  //setting ref to be of type DatabaseReference
  private let ref: DatabaseReference
  
  init(userId: String) {
    ref = Database.database()
      .reference()
      .child("users")
      .child(userId)
      .child("parties")
  }
    
  func createParty() {
      let randomValue = Int.random(in: 0 ..< 0x1_000_000)
      let hexString = String(format: "%06X", randomValue)
      //return hexString
      print(hexString)
  }
    
  func joinParty(with partyId: String) {
    ref.child(partyId)
        .child("joinedAt")
        .setValue(ServerValue.timestamp())
    print("partyID set")
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

