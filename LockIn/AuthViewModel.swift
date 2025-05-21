//
//  AuthViewModel.swift
//  LockIn
//
//  Created by Matthew Lu on 5/9/25.
//

import FirebaseCore
import FirebaseAuth
import FirebaseDatabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    
    private var handle: AuthStateDidChangeListenerHandle?

      init() {
        // 1) read the persisted user (if any)
        self.currentUser = Auth.auth().currentUser

        // 2) listen for future sign-in / sign-out events
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
          self?.currentUser = user
        }
      }

      deinit {
        if let h = handle {
          Auth.auth().removeStateDidChangeListener(h)
        }
      }

    //enum allows you to define a finite, related set of cases
    enum SignUpError: LocalizedError {
      case emailAlreadyInUse
      case invalidEmail
      case weakPassword
      case unknown
      
      var errorDescription: String? {
        switch self {
        case .emailAlreadyInUse:
          return "That email’s already in use—please sign in instead."
        case .invalidEmail:
          return "Invalid email format. Please try a different email."
        case .weakPassword:
          return "Password must be at least 6 characters long, include one uppercase letter, one lowercase letter, one number, and one special character."
        case .unknown:
          return "Invalid Email Address or Weak Password. Please Try Again."
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
            //we are checking if the email already exists in the database
            let ref = Database.database().reference().child("users")
            let query = ref.queryOrdered(byChild: "email").queryEqual(toValue: email)
            do {
                  let snapshot = try await query.getData()
                  if snapshot.exists() {
                      throw SignUpError.emailAlreadyInUse
                  }
            //if the error was the one we threw, just rethrow the error
            } catch let error as SignUpError {
                throw error
            } catch {
                throw SignUpError.weakPassword
            }
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
              throw SignUpError.unknown
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

