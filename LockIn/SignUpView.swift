//
//  ContentView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/8/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    //    @StateObject private var partyVM = PartyViewModel( userId: authVM.currentUser?.uid)
    @State private var email = ""
    @State private var password = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            NavigationView {
                VStack {
                    Text("lmnt")
                        .font(.system(size: 23, weight:
                                .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .offset(y: -200)
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Sign Up") {
                      Task {
                        do {
                          let result = try await authVM.signUp(email: email, password: password)
                          print("✅", result)
                          alertMessage = "Success! Account Created. Please Sign in"
                        } catch {
                          print("🛑",error.localizedDescription)
                          alertMessage = error.localizedDescription
                          showingAlert = true
                        }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    
                    NavigationLink(destination: LoginView()) {
                        Label("Sign In", systemImage: "person.fill")
                            .padding()
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    
                    if !alertMessage.isEmpty {
                        Text(alertMessage)
                            .foregroundColor(showingAlert ? .red : .green)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    SignUpView()
}
