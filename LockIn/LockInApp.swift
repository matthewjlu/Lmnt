//
//  LockInApp.swift
//  LockIn
//
//  Created by Matthew Lu on 5/8/25.
//


import SwiftUI

@main
struct LockInApp: App {
  // Hook up your AppDelegate so Firebase gets configured
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}
