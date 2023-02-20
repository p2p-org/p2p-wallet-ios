//
//  TransactionDetailStatusView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 08.02.2023.
//

import SwiftUI
import KeyAppUI

struct TransactionDetailStatusAppearance {
    let image: UIImage
    let imageSize: CGSize
    let backgroundColor: Color
    let circleColor: Color
    let imageColor: Color

    init(status: DetailTransactionStatus) {
        switch status {
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


struct TransactionDetailStatusView: View {
    let status: DetailTransactionStatus

    @State private var isRotatingAnimation = false
    @State private var isColorTransition = true
    @State private var previousAppearance: TransactionDetailStatusAppearance?
    @State private var currentAppearance: TransactionDetailStatusAppearance

    private let rotationAnimation = Animation.linear(duration: 0.2).speed(0.1).repeatForever(autoreverses: false)
    private let scaleAnimation = Animation.easeInOut(duration: 0.2)
    private let errorMessageTapAction: () -> Void

    init(status: DetailTransactionStatus, errorMessageTapAction: @escaping () -> Void) {
        self.status = status
        self.errorMessageTapAction = errorMessageTapAction
        self.currentAppearance = TransactionDetailStatusAppearance(status: status)
        self.previousAppearance = nil
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

                    if case .loading = status {
                        Image(uiImage: .transactionStatusLoadingWrapper)
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
                    switch status {
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
        .onChange(of: status) { value in
            previousAppearance = currentAppearance
            currentAppearance = TransactionDetailStatusAppearance(status: value)
            isColorTransition = false
            withAnimation(scaleAnimation) { isColorTransition = true }
        }
    }
}

private extension Text {
    func messageStyled() -> some View {
        return self.apply(style: .text4)
            .foregroundColor(Color(Asset.Colors.night.color))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct TransactionDetailStatusView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionDetailStatusView(status: .succeed(message: L10n.theTransactionHasBeenSuccessfullyCompleted)) {}
    }
}
