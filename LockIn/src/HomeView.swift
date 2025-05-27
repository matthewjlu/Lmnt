import SwiftUI
import UIKit

struct HomeView: View {
    @State private var selectedIndex = 0
    let bgImage   = "image1_1950"
    let buttonBg  = "image2_1953"
    let lockIcon  = "image3_2166"
    let navIcons  = ["image4_2177", "image5_2180", "image6_2183", "image7_2189"]
    let navTitles = ["Home", "Leaderboard", "Party", "Profile"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(bgImage)
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(width: geo.size.width,
                         height: geo.size.height)
                  .clipped()

                VStack {
                    HStack {
                        Text("LMNT")
                          .font(.custom("BodoniModa-Regular", size: 36))
                          .foregroundColor(.white)
                          .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                    Spacer()
                    
                    VStack {
                        ScrambleText(
                          text: "Time Off Technology:",
                          font: .custom("Signika", size: 30),
                          delay: 0.5
                        )
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .offset(x: 0, y: 150)
                        ScrambleText(
                          text: "2000 Hours",
                          font: .custom("Signika", size: 45),
                          delay: 0.5
                        )
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .offset(x: 0, y: 160)
                        Spacer()
                    }
                    .padding(.top, 100)
                    .padding(.horizontal, 24)

                    Spacer()
                    
                    Button{
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
                    .padding(.bottom, 10)

                    HStack {
                        // Home
                        Button {
                            selectedIndex = 0
                        } label: {
                            VStack(spacing: 4) {
                                Image("image4_2177")
                                  .resizable()
                                  .frame(width: 40, height: 40)
                                  .opacity(selectedIndex == 0 ? 1 : 0.6)
                                Text("Home")
                                  .font(.custom("Habibi-Regular", size: 12))
                                  .foregroundColor(.white)
                                  .fontWeight(.bold)
                                  .opacity(selectedIndex == 0 ? 1 : 0.6)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .offset(y: 20)

                        // Leaderboard
                        Button {
                            selectedIndex = 1
                        } label: {
                            VStack(spacing: 4) {
                                Image("image5_2180")
                                  .resizable()
                                  .frame(width: 50, height: 45)
                                  .opacity(selectedIndex == 1 ? 1 : 0.6)
                                Text("Leaderboard")
                                  .font(.custom("Habibi-Regular", size: 11))
                                  .foregroundColor(.white)
                                  .fontWeight(.bold)
                                  .opacity(selectedIndex == 1 ? 1 : 0.6)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .offset(y: 20)
                        .offset(x: 5)

                        // Party
                        Button {
                            selectedIndex = 2
                        } label: {
                            VStack(spacing: 4) {
                                Image("image6_2183")
                                  .resizable()
                                  .frame(width: 45, height: 55)
                                  .opacity(selectedIndex == 2 ? 1 : 0.6)
                                Text("Party")
                                  .font(.custom("Habibi-Regular", size: 12))
                                  .foregroundColor(.white)
                                  .fontWeight(.bold)
                                  .opacity(selectedIndex == 2 ? 1 : 0.6)
                                  .offset(y: -5)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .offset(y: 20)
                        .offset(x: 5)

                        // Profile
                        Button {
                            selectedIndex = 3
                        } label: {
                            VStack(spacing: 4) {
                                Image("image7_2189")
                                  .resizable()
                                  .frame(width: 50, height: 45)
                                  .opacity(selectedIndex == 3 ? 1 : 0.6)
                                Text("Profile")
                                  .font(.custom("Habibi-Regular", size: 12))
                                  .foregroundColor(.white)
                                  .fontWeight(.bold)
                                  .opacity(selectedIndex == 3 ? 1 : 0.6)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .offset(y: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)

                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// ← PreviewProvider must be at file scope, NOT inside CustomView1
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
          .frame(width: 393, height: 852)
          .previewLayout(.sizeThatFits)
          .preferredColorScheme(.dark)
    }
}

