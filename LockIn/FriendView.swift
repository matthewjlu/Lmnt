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
  @State private var foundEmail: String?
  @State private var isSearching = false

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
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)

          if isSearching {
            ProgressView()
          } else if let email = foundEmail {
            Text("Found user! \(email)")
              .foregroundColor(.green)
          } else if !searchText.isEmpty {
            Text("No user found")
              .foregroundColor(.red)
          }
        }
        .padding()
          //loads when the user goes to the friends page
        .onAppear(perform: loadMyCode)
          //queries when the user starts searching
        .onChange(of: searchText) {
          lookupFriendCode(searchText)
        }
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

  // lookup the entered code:
  private func lookupFriendCode(_ code: String) {
    // clear any previous result
    foundEmail = nil

    // if they wiped the field, nothing to do
    guard !code.isEmpty else { return }

    isSearching = true
    Task {
      defer { isSearching = false }

      do {
        let snapshot = try await Firestore.firestore()
          .collection("users")
          .whereField("friendCode", isEqualTo: code)
          .limit(to: 1)
          .getDocuments()

        if let doc = snapshot.documents.first,
           let email = doc.get("email") as? String {
          foundEmail = email
        } else {
          foundEmail = nil
        }
      } catch {
        print("lookup error:", error)
        foundEmail = nil
      }
    }
  }
}
