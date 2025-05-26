//
//  PartyView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/15/25.
//

import SwiftUI

public struct PartyView: View {
    
    @EnvironmentObject private var authVM: AuthViewModel
    
    public var body: some View {
        Button("Sign Out") {
            Task {
                authVM.signOut()
            }
        }
        
        Group {
            if let uid = authVM.currentUser?.uid {
                if let email = authVM.currentUser?.email {
                    let party = PartyViewModel()
                    Button("Create Party") {
                        Task {
                            do {
                                try await party.createParty(userId: uid, email: email)
                            } catch {
                                return "ERROR"
                            }
                            return "SUCCCESS!"
                        }
                    }
                } else {
                    Text("Error!!!!")
                }
            } else {
                Text("🔒 Please sign in to see your party")
            }
        }
        .padding()
        
        Group {
            if let id = authVM.currentUser?.uid {
                Button("Request to Join Party") {
                    Task {
                        let party = PartyViewModel()
                        do {
                            try await party.requestJoin(partyId: "SuvwUjq8JoXg0POZ8876", userId: id)
                            print("✅ Requested party successfully")
                        } catch {
                            print("❌ Failed to join party:", error)
                        }
                    }
                }
            } else {
                // 4️⃣ handle the “not signed in” case
                Text("🔒 Please sign in to join a party.")
            }
        }
        .padding()
        
        Group {
            if let id = authVM.currentUser?.uid {
                Button("Ready Up") {
                    Task {
                        let party = PartyViewModel()
                        do {
                            try await party.readyUp(partyId: "SuvwUjq8JoXg0POZ8876", userId: id)
                            print("✅ Readied Up successfully")
                        } catch {
                            print("❌ Failed to Ready Up:", error)
                        }
                    }
                }
            } else {
                // 4️⃣ handle the “not signed in” case
                Text("🔒 Please sign in to join a party.")
            }
        }
        .padding()
    }
}

