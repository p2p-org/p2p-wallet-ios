//
//  LoadingAnimationLayout.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import KeyAppUI
import SwiftUI

struct LoadingAnimationLayout: View {
    let title: String
    let subtitle: String
    let isProgressVisible: Bool

    private let mainColor = Color(Asset.Colors.night.color)
    private let animationSize = CGSize(width: 272, height: 204)

    var body: some View {
        ZStack {
            Color(Asset.Colors.lime.color)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                LottieView(lottieFile: "walletAnimation", loopMode: .loop)
                    .scaledToFill()
                    .frame(width: animationSize.width, height: animationSize.height)

                Text(title)
                    .apply(style: .largeTitle)
                    .foregroundColor(mainColor)
                    .padding(.top, 36)
                    .transition(.opacity.animation(.linear))

                ZStack {
                    IndeterminateProgressBar(indicatorColor: mainColor)
                        .frame(width: 113)
                        .opacity(isProgressVisible ? 1 : 0)
                    Text(subtitle)
                        .apply(style: .title3)
                        .foregroundColor(mainColor)
                        .opacity(isProgressVisible ? 0 : 1)
                }
                .transition(.opacity.animation(.linear))
                .padding(.top, 16)
            }
            .edgesIgnoringSafeArea(.top)
            .padding(.horizontal, 20)
            .padding(.bottom, animationSize.height / 2)
        }
    }
}

struct LoadingAnimationLayout_Previews: PreviewProvider {
    static var previews: some View {
        LoadingAnimationLayout(title: "Hello", subtitle: "World", isProgressVisible: true)
    }
}
