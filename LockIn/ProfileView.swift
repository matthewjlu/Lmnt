//
//  ProfileView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/27/25.
//

import SwiftUI
import UIKit
import FirebaseFirestore

public struct ProfileView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    private let bgImage = "image1_1950"

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
                    Button("Sign Out") {
                        Task {
                            authVM.signOut()
                        }
                    }
                    .font(.custom("SF Pro", size: 15))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    NavigationLink(destination: FriendView()) {
                        Text("Friends")
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .font(.custom("SF Pro", size: 15))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                }
            }
        }
    }
}
