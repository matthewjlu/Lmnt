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
                    
                    //show incoming friend requests in a scrolling List
                    ScrollView {
                        List {
                            Section(header:
                                        Text("Your Friend Requests: \(authVM.friendRequests.count)")
                                .font(.custom("SF Pro", size: 15))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            ) {
                                ForEach(authVM.friendRequests, id: \.self) { request in
                                    Text(request)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .font(.custom("SF Pro", size: 15))
                    .fontWeight(.bold)
                    .frame(maxHeight: CGFloat(authVM.friendRequests.count) * 60)
                    .onAppear {
                        if let uid = authVM.currentUser?.uid {
                            authVM.startListeningReq(uid: uid)
                        }
                    }
                    .onDisappear {
                        authVM.stopListeningReq()
                    }
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
    
#Preview {
    FriendView()
        .environmentObject(AuthViewModel())
}

