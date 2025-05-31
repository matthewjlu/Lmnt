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
  @State private var friendCode: String = "loading…"
  @State private var searchText: String = ""

  private let bgImage = "image1_1950"

  public var body: some View {
    NavigationView {
      ZStack {
        Image(bgImage)
          .resizable()
          .scaledToFill()
          .ignoresSafeArea()

        VStack(spacing: 16) {
          Text("Your Friend Code: \(friendCode)")
            .font(.custom("SF Pro", size: 15))
            .fontWeight(.bold)
            .foregroundColor(.white)

          // the searchable field
          TextField("Enter a friend code…", text: $searchText)
            .textInputAutocapitalization(.never)
            .autocapitalization(.none)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
            
            Button("Invite!") {
                Task {
                    lookupFriendCode(searchText)
                }
            }
            
            Text("Your Friend Requests \(authVM.friendRequests)")
                .font(.custom("SF Pro", size: 15))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .onAppear {
                    if let uid = authVM.currentUser?.uid {
                        authVM.startListeningReq(uid: uid)
                    }
                }
                .onDisappear {
                    authVM.stopListeningReq()
                }
       
        }
        .padding()
          //loads when the user goes to the friends page
        .onAppear(perform: loadMyCode)
      }
      .navigationTitle("Friends")
    }
  }

  // load your own friendCode once:
  private func loadMyCode() {
    Task {
      guard let uid = authVM.currentUser?.uid else {
        friendCode = "no user"
        return
      }
      do {
        let doc = try await Firestore.firestore()
          .collection("users")
          .document(uid)
          .getDocument()
        friendCode = doc.get("friendCode") as? String ?? "none"
      } catch {
        friendCode = "error"
      }
    }
  }
    
  // lookup the entered code and add to the found user's friendRequests array
  @MainActor
  private func lookupFriendCode(_ code: String) {
    // if they wiped the field, nothing to do
    guard !code.isEmpty else { return }
    Task {@MainActor in

      do {
          //first we find any users who have the friendCode that the user types in
        let snapshot = try await Firestore.firestore()
          .collection("users")
          .whereField("friendCode", isEqualTo: code)
          .limit(to: 1)
          .getDocuments()
        //doc is a QueryDocumentSnapshot
        if let doc = snapshot.documents.first {
            //then we append the user's email to the person who's friend code we found
            let data = doc.data()
            guard var existingReq = data["friendRequests"] as? [String]
            else {
                return
            }
            if let myEmail = authVM.currentUser?.email {
                existingReq.append(myEmail)
            }
            try await doc.reference.setData(["friendRequests": existingReq], merge: true)
        } else {
          return
        }
      } catch {
        print("lookup error:", error)
        return
      }
    }
  }
}
