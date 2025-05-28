//
//  ProfileView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/27/25.
//

import SwiftUI
import UIKit


public struct ProfileView: View {
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
                // Sign-out button
                Button("Sign Out") {
                    Task {
                        authVM.signOut()
                    }
                }
            }
        }
    }
}
