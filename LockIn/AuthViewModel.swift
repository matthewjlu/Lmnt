//
//  AuthViewModel.swift
//  LockIn
//
//  Created by Matthew Lu on 5/9/25.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    private var handle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        // 1) read the persisted user (if any)
        self.currentUser = Auth.auth().currentUser
        
        // 2) listen for future sign‐in / sign‐out events
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }

    deinit {
        if let h = handle {
            Auth.auth().removeStateDidChangeListener(h)
        }
    }

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
            case .unknown(let err):
                return err.localizedDescription
            }
        }
    }

    //Create Firebase Auth user & Firestore profile
    func signUp(email: String, password: String) async throws -> String {
        do {
            //1. create Auth user
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            //2. write Firestore profile
            let userDB = UserDBViewModel(userId: result.user.uid)
            userDB.writeUserData(email: email)
            
            return "Success!"
            
        } catch let nsError as NSError {
            // 3. if Auth.createUser fails, check if Firestore already has that email
            let usersCol = db.collection("users")
            let query = usersCol.whereField("email", isEqualTo: email)
            
            do {
                let snapshot = try await query.getDocuments()
                if !snapshot.documents.isEmpty {
                    throw SignUpError.emailAlreadyInUse
                }
            } catch let error as SignUpError {
                throw error
            } catch {
                // fallback if query itself failed
                throw SignUpError.weakPassword
            }
            
            // 4. map specific AuthErrorCode cases
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
    
    //Sign in & update lastLogin in Firestore
    func signIn(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let userDB = UserDBViewModel(userId: result.user.uid)
            userDB.updateLastLogin()
            self.currentUser = result.user
            return "Success"
            
        } catch let nsError as NSError {
            guard let code = AuthErrorCode(rawValue: nsError.code) else {
                throw nsError
            }
            switch code {
            //add all the cases
            default:
                throw LoginError.unknown(nsError)
            }
        }
    }
    
    //Sign out from Firebase Auth
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

