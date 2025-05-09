//
//  ContentView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/8/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack(spacing: 10) {
            Image("LMN")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .offset(y: 20)
            Text("lmnt")
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .offset(y: 20)
        }
        VStack {
            Spacer()
            Button("Join Party", systemImage: "figure.walk", action: join)
            Button("Leave", systemImage: "figure.walk.departure", action: leave)
        }
        .padding()
    }
}

func join(){
    let vm = PartyViewModel(partyId: "123", userId: "1234")
    vm.requestJoin()
}

func leave(){
    let vm = PartyViewModel(partyId: "123", userId: "1234")
    vm.requestLeave()
    
}

#Preview {
    ContentView()
}
