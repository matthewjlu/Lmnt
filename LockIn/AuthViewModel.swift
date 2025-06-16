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
    @Published var hoursLockedIn: Int = -1
    @Published var friendRequests: [String] = []
    @Published var friends: [String] = []
    @Published var friendCode : String = "loading..."
    @Published var userPartyCode: String = ""
    
    private var handle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    private var listenerFriend: ListenerRegistration?
    private var listenerReq: ListenerRegistration?
    private var listenerHours: ListenerRegistration?
    private var hasCheckedPartyCode = false
    
    init() {
        // 1) read the persisted user (if any)
        self.currentUser = Auth.auth().currentUser
        
        if currentUser != nil {
            self.loadHours()
        }
        
        // 2) listen for future sign‐in / sign‐out events
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.loadHours()
            self?.hasCheckedPartyCode = false
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
            try await _ = userDB.writeUserData(email: email)
            
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
    
    //calculates the user's hours spent locked in
    func loadHours() {
        Task { @MainActor in
            guard let uid = currentUser?.uid else { return }
            do {
                let snap = try await db.collection("users")
                    .document(uid)
                    .getDocument()
                let data = snap.data() ?? [:]
                if let i = data["hoursLockedIn"] as? Int {
                    hoursLockedIn = i
                }
                else if let d = data["hoursLockedIn"] as? Double {
                    hoursLockedIn = Int(d)
                }
                else if let i64 = data["hoursLockedIn"] as? Int64 {
                    hoursLockedIn = Int(i64)
                }
                else {
                    hoursLockedIn = -1
                }
            } catch {
                hoursLockedIn = -1
            }
        }
    }

    func loadMyCode() async {
        guard let uid = self.currentUser?.uid else {
          friendCode = "no user"
          return
        }
        do {
          let doc = try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument()
            friendCode =  doc.get("friendCode") as? String ?? "none"
        } catch {
            friendCode =  "error"
        }
    }
    
    func checkExistingPartyCode() async -> String? {
           //prevent multiple checks from happening
           guard !hasCheckedPartyCode else { return userPartyCode.isEmpty ? nil : userPartyCode }
           
           guard let uid = currentUser?.uid else { return nil }
           
           do {
               //get the user's current party code from Firestore
               let userDoc = try await db
                   .collection("users")
                   .document(uid)
                   .getDocument()
               
               if let partyCode = userDoc.data()?["partyCode"] as? String,
                  !partyCode.isEmpty {
                   
                   //check if the party still exists
                   let partyDoc = try await db.collection("parties")
                       .document(partyCode)
                       .getDocument()
                   
                   if partyDoc.exists {
                       print("Found existing party: \(partyCode)")
                       userPartyCode = partyCode
                       hasCheckedPartyCode = true
                       return partyCode
                   } else {
                       // Party doesn't exist anymore, clear the user's partyCode
                       try await db
                           .collection("users")
                           .document(uid)
                           .setData(["partyCode": ""], merge: true)
                       print("Party no longer exists, cleared partyCode")
                       userPartyCode = ""
                       hasCheckedPartyCode = true
                       return nil
                   }
               } else {
                   userPartyCode = ""
                   hasCheckedPartyCode = true
                   return nil
               }
               
           } catch {
               print("Error checking existing party code: \(error)")
               hasCheckedPartyCode = true
               return nil
           }
       }
       
       //helper function to reset party code chec
       func resetPartyCodeCheck() {
           hasCheckedPartyCode = false
           userPartyCode = ""
       }
    
    func lookupFriendCode(_ code: String) async {
        guard !code.isEmpty else { return }

        do {
            //snapshot of the databse of the person we are trying to request as a friend
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .whereField("friendCode", isEqualTo: code)
                .limit(to: 1)
                .getDocuments()
            
            if let doc = snapshot.documents.first {
                let data = doc.data()

                var existingReq = data["friendRequests"] as? [String] ?? []
                let otherEmail = data["email"] as? String ?? ""

                if let myEmail = self.currentUser?.email {
                    //check for if we are already in friend req, if we adding ourself, if we already in the other user's friends
                    if existingReq.contains(myEmail) || myEmail == otherEmail || friends.contains(otherEmail) {
                        return
                    }
                    existingReq.append(myEmail)
                }

                //write it back to Firestore
                try await doc.reference.setData(
                    ["friendRequests": existingReq],
                    merge: true
                )
            }
        } catch {
            print("lookup error:", error)
        }
    }
    
    func acceptReq(request: String) async {
        var friendReqs: [String] = []
        var friendsList: [String] = []
        
        guard let uid = self.currentUser?.uid else {
          return
        }
        do {
          //find the user's friendRequests to remove the request and add to the friends field of the user
          let doc = try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument()
          friendReqs = doc.get("friendRequests") as? [String] ?? []
          friendsList = doc.get("friends") as? [String] ?? []
          friendReqs.removeAll { $0 == request }
          friendsList.append(request)
          try await doc.reference.setData(
              ["friendRequests": friendReqs],
              merge: true
          )
          try await doc.reference.setData(
              ["friends": friendsList],
              merge: true
          )
            
          //add to the friendsList of the other user whose friendRequest got accepted
          let snapshot = try await Firestore.firestore()
              .collection("users")
              .whereField("email", isEqualTo: request)
              .limit(to: 1)
              .getDocuments()
          
          if let doc = snapshot.documents.first {
            let data = doc.data()
            var friends: [String] = data["friends"] as? [String] ?? []
            guard let email = self.currentUser?.email else {
              return
            }
            friends.append(email)
            try await doc.reference.setData(
              ["friends": friends],
              merge: true
            )
          }
        } catch {
            return
        }
    }

    
    func declineReq(request: String) async {
        var friendReqs: [String] = []
        guard let uid = self.currentUser?.uid else {
          return
        }
        do {
          let doc = try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument()
          friendReqs = doc.get("friendRequests") as? [String] ?? []
          friendReqs.removeAll { $0 == request }
          try await doc.reference.setData(
              ["friendRequests": friendReqs],
              merge: true
          )
        } catch {
            return
        }
    }

    
    //basically always listening for changes to the user's friendRequests field
    func startListeningReq(uid: String) {
        listenerReq = Firestore.firestore()
            .collection("users")
            .document(uid)
            .addSnapshotListener { [weak self] snap, error in
                guard let data = snap?.data(),
                      let requests = data["friendRequests"] as? [String]
                else { return }
                self?.friendRequests = requests
            }
    }
    
    //makes sure that the listener stops when the user leaves the page
    func stopListeningReq() {
        listenerReq?.remove()
    }
    
    //basically always listening for changes to the user's friends field
    func startListeningFriend(uid: String) {
        listenerFriend = Firestore.firestore()
            .collection("users")
            .document(uid)
            .addSnapshotListener { [weak self] snap, error in
                guard let data = snap?.data(),
                      let friends = data["friends"] as? [String]
                else { return }
                self?.friends = friends
            }
    }
    
    //makes sure that the listener stops when the user leaves the page
    func stopListeningFriend() {
        listenerFriend?.remove()
    }
    
    func startListeningHrs(uid: String) {
        listenerHours = Firestore.firestore()
            .collection("users")
            .document(uid)
            .addSnapshotListener { [weak self] snap, error in
                guard let data = snap?.data(),
                      let requests = data["hoursLockedIn"] as? Int
                else { return }
                self?.hoursLockedIn = requests
            }
    }
    
    
    func stopListeningHrs() {
        listenerHours?.remove()
    }
}


