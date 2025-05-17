//
//  AuthViewModel.swift
//  LockIn
//
//  Created by Matthew Lu on 5/9/25.
//

import FirebaseCore
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    //enum allows you to define a finite, related set of cases
    enum SignUpError: LocalizedError {
      case emailAlreadyInUse
      case invalidEmail
      case weakPassword
      case unknown(Error)
      
      var errorDescription: String? {
        switch self {
        case .emailAlreadyInUse:
          return "That email’s already in use—please sign in instead."
        case .invalidEmail:
          return "Invalid email format. Please try a different email."
        case .weakPassword:
          return "Password must be at least 6 characters long, include one uppercase letter, one lowercase letter, one number, and one special character."
        case .unknown(let err):
          return err.localizedDescription
        }
      }
    }
    
    enum LoginError: LocalizedError {
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            //add the actual cases later on
            case .unknown(let err):
                return err.localizedDescription
            }
        }
    }

    
    func signUp(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let userDB = UserDBViewModel(userId:result.user.uid)
            userDB.writeUserData(email: email)
            return "Success!"
          } catch let nsError as NSError {
            guard let code = AuthErrorCode(rawValue: nsError.code) else {
              throw nsError
            }
            switch code {
            case .emailAlreadyInUse:
              throw SignUpError.emailAlreadyInUse
            case .invalidEmail:
              throw SignUpError.invalidEmail
            case .weakPassword:
              throw SignUpError.weakPassword
            default:
              throw SignUpError.unknown(nsError)
            }
          }
        }
    
    func signIn(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let userDB = UserDBViewModel(userId:result.user.uid)
            userDB.updateLastLogin()
            self.currentUser = result.user
            return "Success"
        } catch let nsError as NSError {
            //add the case statements
            guard let code = AuthErrorCode(rawValue: nsError.code) else {
              throw nsError
            }
            switch code {
            default:
                throw LoginError.unknown(nsError)
            }
        }
    }
        
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

