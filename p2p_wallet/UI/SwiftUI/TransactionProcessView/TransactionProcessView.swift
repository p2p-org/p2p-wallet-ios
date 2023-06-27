//
//  TransactionProcessView.swift
//  p2p_wallet
//
//  Created by Ivan on 28.03.2023.
//

import Foundation
import SwiftUI
import KeyAppUI

struct TransactionProcessView: View {
    @Binding private var state: TransactionProcessView.Status

    @State private var isRotatingAnimation = false
    @State private var isColorTransition = true
    @State private var previousAppearance: Appearance?
    @State private var currentAppearance: Appearance

    private let rotationAnimation = Animation.linear(duration: 0.2).speed(0.1).repeatForever(autoreverses: false)
    private let scaleAnimation = Animation.easeInOut(duration: 0.2)
    private let errorMessageTapAction: () -> Void

    init(state: Binding<TransactionProcessView.Status>, errorMessageTapAction: @escaping () -> Void) {
        _state = state
        self.currentAppearance = Appearance(state: state.wrappedValue)
        self.previousAppearance = nil
        self.errorMessageTapAction = errorMessageTapAction
    }

    private let maxScaleEffect: CGFloat = 1.0
    private let minScaleEffect: CGFloat = 0

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                ZStack(alignment: .center) {
                    if let previousColor = previousAppearance?.circleColor {
                        Circle()
                            .fill(previousColor)
                            .frame(width: 48, height: 48)
                            .scaleEffect(maxScaleEffect)
                    }

                    if case .loading = state {
                        Image(.transactionStatusLoadingWrapper)
                            .resizable()
                            .frame(width: 48, height: 48)
                            .rotationEffect(.degrees(isRotatingAnimation ? 360 : 0.0))
                            .animation(isRotatingAnimation ? rotationAnimation : .default, value: isRotatingAnimation)
                            .onAppear { DispatchQueue.main.async { isRotatingAnimation = true } }
                    } else {
                        Circle()
                            .fill(currentAppearance.circleColor)
                            .frame(width: 48, height: 48)
                            .scaleEffect(isColorTransition ? maxScaleEffect : minScaleEffect)
                    }

                    Image(uiImage: currentAppearance.image)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(currentAppearance.imageColor)
                        .frame(width: currentAppearance.imageSize.width, height: currentAppearance.imageSize.height)
                }
                .padding(.leading, 5)
                Group {
                    switch state {
                    case let .loading(message), let .succeed(message: message):
                        Text(message)
                            .messageStyled()
                    case let .error(message):
                        Text(message)
                            .messageStyled()
                            .onTapGesture(perform: errorMessageTapAction)
                    }
                }
                .padding(.leading, 2)
                Spacer()
            }
            .padding(13)
        }
        .frame(maxWidth: .infinity)
        .background(currentAppearance.backgroundColor)
        .cornerRadius(12)
        .onChange(of: state) { value in
            previousAppearance = currentAppearance
            currentAppearance = Appearance(state: value)
            isColorTransition = false
            withAnimation(scaleAnimation) { isColorTransition = true }
        }
    }
}

// MARK: - State

extension TransactionProcessView {
    enum Status: Equatable {
        case loading(message: String)
        case succeed(message: String)
        case error(message: NSAttributedString)
    }
}

// MARK: - Appearance

extension TransactionProcessView {
    struct Appearance {
        let image: UIImage
        let imageSize: CGSize
        let backgroundColor: Color
        let circleColor: Color
        let imageColor: Color
        
        init(state: TransactionProcessView.Status) {
            switch state {
            case .loading:
                image = .lightningFilled
                imageSize = CGSize(width: 24, height: 24)
                backgroundColor = Color(Asset.Colors.cloud.color)
                circleColor = Color(Asset.Colors.smoke.color)
                imageColor = Color(Asset.Colors.mountain.color)
            case .succeed:
                image = .lightningFilled
                imageSize = CGSize(width: 24, height: 24)
                backgroundColor = Color(.cdf6cd).opacity(0.3)
                circleColor = Color(.cdf6cd)
                imageColor = Color(.h04D004)
            case .error:
                image = .solendSubtract
                imageSize = CGSize(width: 20, height: 18)
                backgroundColor = Color(.ffdce9).opacity(0.3)
                circleColor = Color(.ffdce9)
                imageColor = Color(Asset.Colors.rose.color)
            }
        }
    }
}

private extension Text {
    func messageStyled() -> some View {
        apply(style: .text4)
            .foregroundColor(Color(Asset.Colors.night.color))
            .fixedSize(horizontal: false, vertical: true)
    }
}
