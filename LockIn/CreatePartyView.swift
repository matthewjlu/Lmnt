//
//  CreatePartyView.swift
//  LMNT
//
//  Created by Matthew Lu on 6/16/25.
//

import SwiftUI
import FirebaseFirestore

public struct CreatePartyView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showFriendsSidebar = false
    //binding creates a two way connection between this view and HomePartyView
    @Binding var path: NavigationPath
    let partyId : String
    private let bgImage = "image1_2005"
    
    public var body: some View {
        ZStack {
            BackgroundImageView(imageName: bgImage)
            
            VStack(spacing: 16) {
                //invite Friends Button
                Button(action: {
                    showFriendsSidebar = true
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Invite Friends")
                    }
                    .font(.custom("SF Pro", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.purple)
                    .cornerRadius(10)
                }
                
                Text("Party Code: \(partyId)")
                    .foregroundColor(.white)
    
                //ready Up
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
        .sheet(isPresented: $showFriendsSidebar) {
            FriendsSidebarView()
                .environmentObject(authVM)
        }
        .onAppear {
            //load friends when view appears
            if let uid = authVM.currentUser?.uid {
                authVM.startListeningFriend(uid: uid)
                authVM.startListeningPartyCode(uid: uid)
            }
        }
        .onDisappear {
            authVM.stopListeningFriend()
            authVM.stopListeningPartyCode()
        }
        .onChange(of: authVM.userPartyCode) { _, _ in
            Task {
                if authVM.userPartyCode == "" {
                    path = NavigationPath()
                }
            }
        }
    }
}



//friends Sidebar View
struct FriendsSidebarView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFriends: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Invite Friends to Party")
                        .font(.custom("SF Pro", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Select friends to invite")
                        .font(.custom("SF Pro", size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                //friends List
                if authVM.friends.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No friends to invite")
                            .font(.custom("SF Pro", size: 18))
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("Add some friends first!")
                            .font(.custom("SF Pro", size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(authVM.friends, id: \.self) { friend in
                                FriendInviteRow(
                                    friendName: friend,
                                    isSelected: selectedFriends.contains(friend),
                                    onToggle: {
                                        if selectedFriends.contains(friend) {
                                            selectedFriends.remove(friend)
                                        } else {
                                            selectedFriends.insert(friend)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Space for bottom button
                    }
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send Invites") {
                        Task {
                            await authVM.sendPartyInvite(selectedFriends: selectedFriends)
                            dismiss()
                        }
                    }
                    .disabled(selectedFriends.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

//individual Friend Row for Selection
struct FriendInviteRow: View {
    let friendName: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                //avatar
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(isSelected ? .purple : .blue)
                
                //friend name
                Text(friendName)
                    .font(.custom("SF Pro", size: 16))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                //selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .purple : .gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
