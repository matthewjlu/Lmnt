import SwiftUI
import UIKit

struct HomeView: View {
    @State private var selection: TabDestination? = nil
    @EnvironmentObject private var authVM: AuthViewModel

    private enum TabDestination: Hashable {
        case home, leaderboard, party, profile
    }

    private let bgImage  = "image1_1950"
    private let buttonBg = "image2_1953"
    private let lockIcon = "image3_2166"

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let topInset    = geo.safeAreaInsets.top
                let bottomInset = geo.safeAreaInsets.bottom

                ZStack {
                    // Full-screen background
                    Image(bgImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    VStack {
                        // Top bar
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

                        VStack(spacing: 16) {
                            ScrambleText(text: "Time Off Technology:", font: .custom("Palatino", size: 30), delay: 0.5)
                                .foregroundColor(.white).fontWeight(.bold)
                            ScrambleText(text: "2000 Hours",              font: .custom("Palatino", size: 45), delay: 0.5)
                                .foregroundColor(.white).fontWeight(.bold)
                        }

                        Spacer()

                        // Block-Now button
                        Button {
                            // your action…
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
                        .padding(.bottom, 20)

                        // Bottom nav bar
                        HStack(spacing: 0) {
                            navLink(for: .home,       icon: "image4_2177", title: "Home")
                            navLink(for: .leaderboard,icon: "image5_2180", title: "Leaderboard")
                                .offset(x: 5)
                            navLink(for: .party,      icon: "image6_2183", title: "Party")
                                .offset(x: 8)
                            navLink(for: .profile,    icon: "image7_2189", title: "Profile")
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, bottomInset + 50)
                    }
                    .padding(.horizontal, 24)
                }
            }
            // 4) Hook up your destinations
            .navigationDestination(for: TabDestination.self) { dest in
                switch dest {
                case .home:
                    PartyView()
                case .leaderboard:
                    PartyView()
                case .party:
                    PartyView()
                case .profile:
                    PartyView()
                }
            }
        }
    }


    @ViewBuilder
    private func navLink(
        for dest: TabDestination,
        icon: String,
        title: String
    ) -> some View {
        NavigationLink(value: dest) {
            VStack(spacing: 4) {
                Image(icon)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .opacity(selection == dest ? 1 : 0.6)

                Text(title)
                    .font(.custom("Palatino", size: 12))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(selection == dest ? 1 : 0.6)
            }
            .frame(maxWidth: .infinity)
        }
        .onTapGesture {
            selection = dest
        }
        .buttonStyle(.plain)
    }
}

// Previews
struct HomeView_Previews: PreviewProvider {
    @EnvironmentObject private var authVM: AuthViewModel
    static var previews: some View {
        HomeView()
            .environmentObject(AuthViewModel())
            .previewDevice("iPhone 16")
            .preferredColorScheme(.dark)
    }
}

