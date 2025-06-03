//
//  RootView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/15/25.
//
import SwiftUI
import FamilyControls

struct RootView: View {
    //environment object allows us to share variables across Views while also updating the variable between views
    @EnvironmentObject var authvm: AuthViewModel
    @EnvironmentObject var partyvm: PartyViewModel
    let center = AuthorizationCenter.shared
    
    var body: some View {
        Group {
            if authvm.currentUser == nil {
              SignUpView()
            } else {
              MainTabView()
                .onAppear {
                    Task {
                        do {
                            try await center.requestAuthorization(for: .individual)
                        } catch {
                            print("User Failed to Authorize")
                        }
                    }
                }
            }
        }
    }
}

