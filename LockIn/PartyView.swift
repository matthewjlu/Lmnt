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
            let uid = "cXxSEN6c9KS5mfrpwDOb4mAfdU62"
            if let email = authVM.currentUser?.email {
                Button("Join Party") {
                    Task {
                        let party = PartyViewModel()
                        do {
                            try await party.joinParty(userId: uid, email: email)
                            print("✅ Joined party successfully")
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
    }
}

