//
//  FriendView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/27/25.
//


import SwiftUI
import FirebaseFirestore

public struct FriendView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var searchText: String = ""
    
    private let bgImage = "image1_1950"
    
    public var body: some View {
        ZStack {
            Image(bgImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                //user friend code
                VStack(spacing: 12) {
                    Text("Your Friend Code")
                        .font(.custom("SF Pro", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(authVM.friendCode)
                        .font(.custom("SF Pro", size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                }
                .padding(.top, 100) // Space for navigation
                .padding(.bottom, 20)
                
                //place to invite people
                VStack(spacing: 12) {
                    TextField("Enter a friend code…", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 20)
                    
                    Button("Send Friend Request") {
                        Task {
                            await authVM.lookupFriendCode(searchText)
                        }
                    }
                    .font(.custom("SF Pro", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 32)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(searchText.isEmpty)
                }
                .padding(.bottom, 20)
                
                //make it so that you can scroll through
                ScrollView {
                    VStack(spacing: 20) {
                        //tells the user their friend requests if it's not empty
                        if !authVM.friendRequests.isEmpty {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Friend Requests")
                                        .font(.custom("SF Pro", size: 20))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(authVM.friendRequests.count)")
                                        .font(.custom("SF Pro", size: 16))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(authVM.friendRequests, id: \.self) { request in
                                        FriendRequestRow(request: request)
                                    }
                                }
                            }
                        }
                        
                        //tells the user how many friends they have
                        VStack(spacing: 12) {
                            HStack {
                                Text("Friends")
                                    .font(.custom("SF Pro", size: 20))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(authVM.friends.count)")
                                    .font(.custom("SF Pro", size: 16))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            
                            //display if someone has no friends yet
                            if authVM.friends.isEmpty {
                                Text("No friends yet. Send some friend requests!")
                                    .font(.custom("SF Pro", size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.vertical, 30)
                            } else {
                                LazyVStack(spacing: 8) {
                                    ForEach(authVM.friends, id: \.self) { friend in
                                        FriendsRow(request: friend)
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 10)
                }
            }
            .onAppear {
                if let uid = authVM.currentUser?.uid {
                    authVM.startListeningReq(uid: uid)
                    authVM.startListeningFriend(uid: uid)
                }
            }
            .onDisappear {
                authVM.stopListeningReq()
                authVM.stopListeningFriend()
            }
            .task {
                await authVM.loadMyCode()
            }
        }
    }
}

// Cleaned up Friend Request Row
struct FriendRequestRow: View {
    let request: String
    @EnvironmentObject private var authVM: AuthViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            //avatar
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 35, height: 35)
                .foregroundColor(.blue)
            
            //name
            Text(request)
                .font(.custom("SF Pro", size: 16))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            //accept and deny buttons
            HStack(spacing: 8) {
                Button("Accept") {
                    Task { await authVM.acceptReq(request: request) }
                }
                .font(.custom("SF Pro", size: 13))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.green)
                .cornerRadius(6)
                
                Button(action: {
                    Task { await authVM.declineReq(request: request) }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(6)
                }
                .background(Color.red)
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

// Cleaned up Friends Row
struct FriendsRow: View {
    let request: String
    @EnvironmentObject private var authVM: AuthViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            //avatar
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 35, height: 35)
                .foregroundColor(.green)
            
            //name
            Text(request)
                .font(.custom("SF Pro", size: 16))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

#Preview {
    FriendView()
        .environmentObject(AuthViewModel())
}
