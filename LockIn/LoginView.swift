//
//  LoginView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/15/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    //    @StateObject private var partyVM = PartyViewModel( userId: authVM.currentUser?.uid)
    @State private var email = ""
    @State private var password = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("lmnt")
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .offset(y: -200)
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            Button("Sign In") {
              Task {
                do {
                  let result = try await authVM.signIn(email: email, password: password)
                  print("✅", result)
                } catch {
                  print("🛑",error.localizedDescription)
                  alertMessage = error.localizedDescription
                  showingAlert = true
                }
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            if !alertMessage.isEmpty{
                Text(alertMessage)
                    .foregroundStyle(showingAlert ? .red : .green)
            }
        }
    }
}

#Preview {
    LoginView()
}
