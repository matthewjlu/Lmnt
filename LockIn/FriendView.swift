//
//  FriendView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/27/25.
//

import SwiftUI
import UIKit
import FirebaseFirestore

public struct FriendView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var friendCode: String = "loading…"
    private let bgImage = "image1_1950"
    
    
    //add friend code search feature and then have the email show up in the email
    public var body: some View {
        NavigationView{
            ZStack {
                Image(bgImage)
                    .resizable()
                    .scaledToFill()
                //this fills the entire screen
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Sign-out button
                    Text("Your Friend Code: \(friendCode)")
                        .font(.custom("SF Pro", size: 15))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .onAppear {
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
                            if let code = doc.get("friendCode") as? String {
                                friendCode = code
                            } else {
                                print("⚠️ no friendCode found")
                            }
                        } catch {
                            print("Firestore error:", error)
                        }
                    }
                }
            }
        }
    }
}
