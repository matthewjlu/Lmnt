//
//  PartyView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/15/25.
//

import SwiftUI

public struct PartyView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    public var body: some View {
        Button("Sign Out") {
          Task {
              authVM.signOut()
            }
        }
    }
}
