//
//  LockInApp.swift
//  LockIn
//
//  Created by Matthew Lu on 5/8/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct LockInApp: App {
  @StateObject private var authVM = AuthViewModel()
    
  init() {
    FirebaseApp.configure()
  }
  //var body tells the app what to display when app launches and some Scene tells Swift that we will give a Scene
  var body: some Scene {
    //tells the app that we are going to have multiple different windows
    WindowGroup {
      RootView()
        .environmentObject(authVM)
    }
  }
}
