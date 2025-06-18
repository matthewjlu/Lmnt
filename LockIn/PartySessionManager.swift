//
//  PartySessionManager.swift
//  LMNT
//
//  Created by Matthew Lu on 6/18/25.
//

import SwiftUI
import FirebaseFirestore

class PartySessionManager: ObservableObject {
  private var listener: ListenerRegistration?
  @Published var allReady = false
    
  //listener to see if all the members in the party are ready so that we can fire the block
  func join(partyId: String) {
    listener = Firestore.firestore()
      .collection("parties")
      .document(partyId)
      .addSnapshotListener { snap, _ in
        guard let data = snap?.data() else { return }
        let members = data["members"] as? [String] ?? []
        let ready   = data["ready"]   as? [String] ?? []
        if !members.isEmpty && members.count == ready.count {
          self.allReady = true
          self.listener?.remove()
        }
      }
  }

  func leave() {
    listener?.remove()
    self.allReady = false
  }
}

