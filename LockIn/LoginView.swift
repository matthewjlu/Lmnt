//
//  LoginView.swift
//  LockIn
//
//  Created by Matthew Lu on 5/15/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("LMNT")
                .font(.custom("BodoniModa-Regular", size: 36))
                .fontWeight(.bold)
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
                  print("Yes", result)
                } catch {
                  print("No",error.localizedDescription)
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
