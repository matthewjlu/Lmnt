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
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var partyVM: PartyViewModel
    @State private var showInviteAlert = false
    @State private var pendingInvite: (inviter: String, code: String)?
    let center = AuthorizationCenter.shared
    
    var body: some View {
        Group {
            if authVM.currentUser == nil {
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
        .onAppear {
            if let uid = authVM.currentUser?.uid {
                authVM.startListeningPartyRequests(uid: uid)
            }
        }
        .onChange(of: authVM.currentUser?.uid) {
              guard let uid = authVM.currentUser?.uid else { return }
              authVM.startListeningPartyRequests(uid: uid)
        }
        .onChange(of: authVM.incomingPartyInvites) {
            guard !authVM.incomingPartyInvites.isEmpty else { return }
            let (inviter, code) = authVM.incomingPartyInvites.first!
            pendingInvite = (inviter: inviter, code: code)
            showInviteAlert = true
        }
        .alert("Party Invite",
               isPresented: $showInviteAlert,
               presenting: pendingInvite)
        {inviter, code in
            //clear the partyInvites section when user accepts or denies
            Button("Accept") {
                Task {
                    await authVM.removePartyReq()
                    showInviteAlert = false
                    pendingInvite = nil
                    authVM.incomingPartyInvites.removeAll()
                    await authVM.acceptPartyReq(partyId: code)
                }
            }
            
            Button("Decline", role: .cancel) {
                showInviteAlert = false
                pendingInvite = nil
                authVM.incomingPartyInvites.removeAll()
                Task {
                    await authVM.removePartyReq()
                }
            }
        }
        message: {inviter, code in
            Text("You’ve been invited to \(inviter)'s party")
                .font(.custom("Palatino-Bold", size:20))
        }
    }
}
