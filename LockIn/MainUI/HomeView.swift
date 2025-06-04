import SwiftUI
import UIKit
import FirebaseFirestore
import FamilyControls
import DeviceActivity


extension DeviceActivityEvent.Name {
    static let discouraged = Self("encourage")
}

struct HomeView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var isPresented = false
    @StateObject private var model = ScreenTimeViewModel()
    private let bgImage  = "image1_1950"
    private let buttonBg = "image2_1953"
    private let lockIcon = "image3_2166"
    
    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top

            ZStack {
                Image(bgImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack {
                    // ─────── Top Bar ───────
                    HStack {
                        Text("LMNT")
                          .font(.custom("BodoniModa-Regular", size: 36))
                          .foregroundColor(.white)
                          .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.top, topInset - 40)
                    .padding(.horizontal, 24)

                    Spacer()

                    // ───── Scramble Text ────
                    VStack(spacing: 16) {
                        ScrambleText(text: "Time Off Technology:",
                          font: .custom("Palatino", size: 30),
                          delay: 0.5)
                          .foregroundColor(.white)
                          .fontWeight(.bold)
                        ScrambleText(text: "\(authVM.hoursLockedIn) Hours" ,
                          font: .custom("Palatino", size: 45),
                          delay: 0.5)
                          .id(authVM.hoursLockedIn)
                          .onAppear {
                              if let uid = authVM.currentUser?.uid {
                                  authVM.startListeningHrs(uid: uid)
                              }
                          }
                          .onDisappear {
                              authVM.stopListeningHrs()
                          }
                          .foregroundColor(.white)
                          .fontWeight(.bold)
                    }

                    Spacer()
                    
                    Button("Check Data") {
                        Task {
                            await model.fetchData()
                        }
                    }

                    Button {
                        isPresented = true
                    } label: {
                        ZStack {
                            Image(buttonBg)
                              .resizable()
                              .frame(width: 304, height: 71)
                              .cornerRadius(16)
                            HStack(spacing: 12) {
                                Image(lockIcon)
                                  .resizable()
                                  .frame(width: 35, height: 35)
                                Text("Block Now")
                                  .font(.custom("MarkaziText-Bold", size: 40))
                                  .foregroundColor(.white)
                            }
                        }
                    }
                    .familyActivityPicker(isPresented: $isPresented, selection: $model.selectionToDiscourage)
                    .onChange(of: isPresented) {
                        blockApps()
                    }
                    .padding(.bottom, 180)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
          .environmentObject(AuthViewModel())
    }
}

