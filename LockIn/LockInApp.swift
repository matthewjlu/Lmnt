//
//  LockInApp.swift
//  LockIn
//
//  Created by Matthew Lu on 5/8/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import CoreText

@main
struct LockInApp: App {
    @StateObject private var authVM = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
        registerCustomFonts()
    }
    
    //var body tells the app what to display when app launches and some Scene tells Swift that we will give a Scene
    var body: some Scene {
        //tells the app that we are going to have multiple different windows
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
    
    private func registerCustomFonts() {
        // List your font file names *without* extensions here:
        let fonts = [
            "BodoniModa-Regular",
            "Signika-Regular",
            "Habibi-Regular",
            "MarkaziText-Bold"
        ]
        for fontName in fonts {
            guard let url = Bundle.main.url(
                forResource: fontName,
                withExtension: "ttf"
            ) else {
                print("❌ Failed to find \(fontName).ttf in bundle")
                continue
            }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(
                url as CFURL,
                .process,
                &error
            )
            if let err = error?.takeRetainedValue() {
                print("⚠️ Error registering font \(fontName):", err)
            }
        }
    }
}

