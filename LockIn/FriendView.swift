import SwiftUI
import FirebaseFirestore

public struct FriendView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var searchText: String = ""
    
    private let bgImage = "image1_1950"
    
    public var body: some View {
        NavigationView {
            ZStack {
                Image(bgImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    //display the friendCode from the authVM
                    Text("Your Friend Code: \(authVM.friendCode)")
                        .font(.custom("SF Pro", size: 15))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    //searchable field to invite someone by their code
                    TextField("Enter a friend code…", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    Button("Invite!") {
                        Task {
                            await authVM.lookupFriendCode(searchText)
                        }
                    }
                    
                    HStack {
                        Text("Friend Requests")
                            .font(.custom("SF Pro", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(authVM.friendRequests.count)")
                            .font(.custom("SF Pro", size: 16))
                            .foregroundColor(.white)
                    }
                    //show incoming friend requests in a scrolling List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(authVM.friendRequests, id: \.self) { request in
                                FriendRequestRow(request: request)
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                }
                .padding(.vertical)
                .onAppear {
                    if let uid = authVM.currentUser?.uid {
                        authVM.startListeningReq(uid: uid)
                    }
                }
                .onDisappear {
                    authVM.stopListeningReq()
                }
                .padding()
                //when the view appears, call `authVM.loadMyCode()`
                .task {
                    await authVM.loadMyCode()
                }
            }
            .navigationTitle("Friends")
        }
    }
}

//subview extracted for cleaner FriendView
struct FriendRequestRow: View {
    let request: String
    @EnvironmentObject private var authVM: AuthViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // placeholder avatar
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            
            // requester's name
            Text(request)
                .font(.custom("SF Pro", size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            // accept/decline buttons
            HStack(spacing: 8) {
                Button("Accept") {
                    Task { await authVM.acceptReq(request: request)}
                }
                .font(.custom("SF Pro", size: 14))
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.green)
                .cornerRadius(8)
                
                Button(action: {
                    Task { await authVM.declineReq(request: request) }
                }) {
                    Image(systemName: "xmark")
                        .padding(6)
                }
                .background(Color.red)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    FriendView()
        .environmentObject(AuthViewModel())
}
