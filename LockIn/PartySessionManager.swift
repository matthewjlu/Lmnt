//
//  PartySessionManager.swift
//  LMNT
//
//  Created by Matthew Lu on 6/18/25.
//

import SwiftUI
import FirebaseFirestore

//timer functionalities
extension PartySessionManager {
    //setting the timer after the user starts the block
    func setPartyTimer(hours: Int, minutes: Int) {
        partySelectedHours = hours
        partySelectedMinutes = minutes
        partyTimerDuration = TimeInterval((hours * 60 + minutes) * 60)
        partyTimerActive = true
        
        print("Party timer set: \(hours)h \(minutes)m (\(partyTimerDuration) seconds)")
    }
    
    //clear party timer
    func clearPartyTimer() {
        partySelectedHours = 0
        partySelectedMinutes = 0
        partyTimerDuration = 0
        partyTimerActive = false
    }
    
    //get timer info as formatted string
    func getPartyTimerString() -> String {
        return "\(partySelectedHours)h \(partySelectedMinutes)m"
    }
}


class PartySessionManager: ObservableObject {
    private var listener: ListenerRegistration?
    private var activeListener: ListenerRegistration?
    @Published var allReady = false
    @Published var activeParty = false
    @Published var partySelectedHours: Int = 0
    @Published var partySelectedMinutes: Int = 0
    @Published var partyTimerDuration: TimeInterval = 0
    @Published var partyTimerActive: Bool = false
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
    
    func partyActiveListener(partyId: String) {
        activeListener = Firestore.firestore()
            .collection("parties")
            .document(partyId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self else { return }
                
                guard let data = snap?.data() else { return }
                let active = data["active"] as? Bool ?? false
               
                self.activeParty = active
            }
    }
}
