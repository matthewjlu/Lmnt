//
//  PartyView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/15/25.
//

import SwiftUI

public struct PartyView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    private let bgImage = "image1_1950"

    public var body: some View {
        ZStack {
            Image(bgImage)
                .resizable()
                .scaledToFill()
                //this fills the entire screen
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Create Party / Error
                if let uid = authVM.currentUser?.uid,
                   let email = authVM.currentUser?.email
                {
                    Button("Create Party") {
                        Task {
                            let vm = PartyViewModel()
                            do {
                                try await _ = vm.createParty(userId: uid, email: email)
                            } catch {
                            }
                        }
                    }
                } else {
                    Text("🔒 Please sign in to see your party")
                }

                // Request to join
                if let uid = authVM.currentUser?.uid {
                    Button("Request to Join Party") {
                        Task {
                            let vm = PartyViewModel()
                            do {
                                try await vm.requestJoin(partyId: "SuvwUjq8JoXg0POZ8876", userId: uid)
                            } catch {
                            }
                        }
                    }
                }

                // Ready Up
                if let uid = authVM.currentUser?.uid {
                    Button("Ready Up") {
                        Task {
                            let vm = PartyViewModel()
                            do {
                                try await vm.readyUp(partyId: "SuvwUjq8JoXg0POZ8876", userId: uid)
                            } catch {
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

