//
//  TabView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/27/25.
//

import SwiftUI

enum TabDestination: Hashable {
    case home, leaderboard, party, profile
}

struct MainTabView: View {
    //make it so that we load into the app in the home page
    @State private var selection: TabDestination = .home
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                HomeView()
            }
            .tag(TabDestination.home)
            .tabItem {
                Image("image4_2177")
                Text("Home")
            }

            NavigationStack {
                HomeView()
            }
            .tag(TabDestination.leaderboard)
            .tabItem {
                Image("image5_2180")
                Text("Leaderboard")
            }

            NavigationStack {
                HomePartyView()
            }
            .tag(TabDestination.party)
            .tabItem {
                Image("image6_2183")
                Text("Party")
            }

            NavigationStack {
                ProfileView()
            }
            .tag(TabDestination.profile)
            .tabItem {
                Image("image7_2189")
                Text("Profile")
            }
        }
        .accentColor(.white)
    }
}

struct MainTab_View: PreviewProvider {
    static var previews: some View {
        MainTabView()
          .environmentObject(AuthViewModel())
    }
}
