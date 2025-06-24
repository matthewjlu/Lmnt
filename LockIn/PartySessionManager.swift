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
    private var isActive = true
    
    func join(partyId: String) {
        isActive = true
        listener = Firestore.firestore()
            .collection("parties")
            .document(partyId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self, self.isActive else { return }
                
                DispatchQueue.main.async {
                    guard let data = snap?.data(), self.isActive else { return }
                    let members = data["members"] as? [String] ?? []
                    let ready   = data["ready"]   as? [String] ?? []
                    
                    if !members.isEmpty && members.count == ready.count {
                        self.allReady = true
                        self.listener?.remove()
                        self.listener = nil
                    }
                }
            }
    }
    
    func leave() {
        isActive = false
        DispatchQueue.main.async {
            self.listener?.remove()
            self.listener = nil
            self.allReady = false
        }
    }
}
