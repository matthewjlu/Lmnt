import SwiftUI
import UIKit

struct CustomView1: View {
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
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                    Spacer()

        
                    ZStack {
                        Image(buttonBg)
                          .resizable()
                          .frame(width: 304, height: 61)
                          .cornerRadius(16)

                        HStack(spacing: 12) {
                            Image(lockIcon)
                              .resizable()
                              .frame(width: 28, height: 28)
                            Text("Block Now")
                              .font(.custom("MarkaziText-Bold", size: 32))
                              .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 40)

                    HStack {
                        ForEach(navIcons.indices, id: \.self) { i in
                            Button {
                                selectedIndex = i
                            } label: {
                                VStack(spacing: 4) {
                                    Image(navIcons[i])
                                      .resizable()
                                      .frame(width: 28, height: 28)
                                      .opacity(selectedIndex == i ? 1 : 0.6)
                                    Text(navTitles[i])
                                      .font(.custom("Habibi-Regular", size: 12))
                                      .foregroundColor(.white)
                                      .opacity(selectedIndex == i ? 1 : 0.6)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
            .onAppear {
                // Now that UIKit is imported, this compiles
                for family in UIFont.familyNames.sorted() {
                    print("Family: \(family)")
                    for name in UIFont.fontNames(forFamilyName: family) {
                        print("    Font: \(name)")
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// ← PreviewProvider must be at file scope, NOT inside CustomView1
struct CustomView1_Previews: PreviewProvider {
    static var previews: some View {
        CustomView1()
          .frame(width: 393, height: 852)
          .previewLayout(.sizeThatFits)
          .preferredColorScheme(.dark)
    }
}

