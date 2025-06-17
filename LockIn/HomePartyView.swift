//
//  PartyView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/15/25.
//

import SwiftUI
import FirebaseFirestore

enum Route: Hashable {
  case home
  case createParty(id: String)
}

public struct HomePartyView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var path = NavigationPath()
    @State public var code = ""
    @State private var errorMessage: String?
    @State private var hasCheckedPartyCode = false
    
    private let bgImage = "image1_2005"
    
    public var body: some View {
        NavigationStack(path: $path) {
            ZStack{
                BackgroundImageView(imageName: bgImage)
                
                VStack(spacing: 20) {
                    if let uid = authVM.currentUser?.uid,
                       let email = authVM.currentUser?.email
                    {
                        Button("Create Party") {
                            Task {@MainActor in
                                let vm = PartyViewModel()
                                do {
                                    code = try await vm.createParty(userId: uid, email: email)
                                    let newRoute = Route.createParty(id: code)
                                    path.append(newRoute)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    print("Error creating party: \(error)")
                                }
                            }
                        }
                        
                        //request to join
                        if let uid = authVM.currentUser?.uid {
                            Button("Request to Join Party") {
                                Task {
                                    let vm = PartyViewModel()
                                    do {
                                        try await vm.requestJoin(partyId: "SuvwUjq8JoXg0POZ8876", userId: uid)
                                    } catch {
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .createParty(id: let code):
                CreatePartyView(path: $path, partyId: code)
                    .environmentObject(authVM)
                    .navigationBarBackButtonHidden(true)
            default:
                HomePartyView()
                    .environmentObject(authVM)
            }
        }
        //makes persistent party view
        .onAppear {
            if let uid = authVM.currentUser?.uid {
                authVM.startListeningFriend(uid: uid)
                authVM.startListeningPartyCode(uid: uid)
            }
            Task {
                let _ = await authVM.checkExistingPartyCode()
                if authVM.userPartyCode != "" {
                    //whenever you append to path, navigation destination fires
                    let newRoute = Route.createParty(id: authVM.userPartyCode)
                    path.append(newRoute)
                }
            }
        }
        .onDisappear {
            authVM.stopListeningFriend()
            authVM.stopListeningPartyCode()
        }
    
        .onChange(of: authVM.userPartyCode) {
            //logic to make sure that we go back to homepartyview if disband party
            if authVM.userPartyCode == "" {
                path = NavigationPath()
            }
            //logic for instantly switching to createpartyview if accept invitation
            Task {
                let _ = await authVM.checkExistingPartyCode()
                if authVM.userPartyCode != "" {
                    //whenever you append to path, navigation destination fires
                    let newRoute = Route.createParty(id: authVM.userPartyCode)
                    path.append(newRoute)
                }
            }
        }
    }
}

struct BackgroundImageView: View {
    let imageName: String
    
    var body: some View {
        Group {
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    HomePartyView()
        .environmentObject(AuthViewModel())
}


