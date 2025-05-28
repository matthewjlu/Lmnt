//
//  ScrambleText.swift
//  LockIn
//
//  Created by Matthew Lu on 5/26/25.
//

import SwiftUI
import Combine

struct ScrambleText: View {
    let text: String
    let font: Font
    let delay: Double    // how long before it settles
    @State private var display: String = ""
    @State private var timerCancellable: AnyCancellable?
    
    private let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
    
    var body: some View {
        Text(display)
          .font(font)
          .foregroundColor(.white)
          .fontWeight(.bold)
          .onAppear { startScrambling() }
          .onDisappear { timerCancellable?.cancel() }
    }
    
    private func startScrambling() {
        let totalSteps = Int(delay / 0.03)
        var currentStep = 0
        
        timerCancellable = Timer.publish(every: 0.03, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if currentStep < totalSteps {
                    display = scrambledVersion(progress: Double(currentStep) / Double(totalSteps))
                    currentStep += 1
                } else {
                    display = text
                    timerCancellable?.cancel()
                }
            }
    }
    
    private func scrambledVersion(progress: Double) -> String {
        // For each character, when progress passes certain threshold, show real char
        return String(text.enumerated().map { (i, realChar) in
            let threshold = Double(i + 1) / Double(text.count)
            if progress >= threshold {
                return realChar
            } else {
                return characters.randomElement()!
            }
        })
    }
}
