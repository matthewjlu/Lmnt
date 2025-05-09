//
//  LockInApp.swift
//  LockIn
//
//  Created by Matthew Lu on 5/8/25.
//


import SwiftUI
import FirebaseCore

@main
struct LockInApp: App {
  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}
