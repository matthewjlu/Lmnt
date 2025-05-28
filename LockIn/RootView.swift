//
//  RootView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/15/25.
//
import SwiftUI

struct RootView: View {
    //environment object allows us to share variables across Views while also updating the variable between views
    @EnvironmentObject var authvm: AuthViewModel
    @EnvironmentObject var partyvm: PartyViewModel
    
    var body: some View {
        Group {
            if authvm.currentUser == nil {
              SignUpView()
            } else {
              MainTabView()
            }
        }
    }
}

