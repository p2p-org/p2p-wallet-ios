import Foundation
import SolanaSwift
import SwiftUI

struct SwapInputView: View {
    @ObservedObject var viewModel: SwapInputViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(viewModel.title)
                    .subtitleStyle()
                    .accessibilityIdentifier("SwapInputView.\(viewModel.accessibilityIdentifierTokenPrefix)TitleLabel")

                Spacer()

                if viewModel.isEditable && viewModel.balance != nil && !viewModel.isLoading {
                    allButton
                }
            }
            HStack {
                changeTokenButton
                    .layoutPriority(1)
                amountField
            }
            HStack {
                balanceLabel

                Spacer()

                if let fiatAmount = viewModel.fiatAmount, !viewModel.isLoading, fiatAmount > 0 {
                    Text("≈\(fiatAmount.toString(maximumFractionDigits: 2, roundingMode: .down)) \(Defaults.fiat.code)")
                        .subtitleStyle(color: Color(viewModel.fiatAmountTextColor))
                        .lineLimit(1)
                        .accessibilityIdentifier(
                            "SwapInputView.\(viewModel.accessibilityIdentifierTokenPrefix)FiatLabel"
                        )
                }
            }
            .frame(minHeight: 16)
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 12))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(Color(.snow).opacity(viewModel.isEditable ? 1 : 0.6))
        )
    }
}

// MARK: - Subviews

private extension SwapInputView {
    var allButton: some View {
        Button(action: viewModel.allButtonPressed.send, label: {
            HStack(spacing: 4) {
                Text(L10n.all.uppercaseFirst)
                    .subtitleStyle()
                Text("\(viewModel.balanceText) \(viewModel.tokenSymbol)")
                    .apply(style: .label1)
                    .foregroundColor(Color(.sky))
            }
        })
        .accessibilityIdentifier("SwapInputView.\(viewModel.accessibilityIdentifierTokenPrefix)AllButton")
    }

    var changeTokenButton: some View {
        Button {
            viewModel.changeTokenPressed.send()
        } label: {
            HStack {
                Text("\(viewModel.tokenSymbol) \(viewModel.token.isNonStrict ? "⚠" : "")")
                    .apply(style: .title1)
                    .foregroundColor(Color(.night))
                    .if(viewModel.isLoading) { view in
                        view.skeleton(with: true, size: CGSize(width: 84, height: 20))
                    }
                Image(.expandIcon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12)
                    .foregroundColor(Color(.night))
            }
        }
        .allowsHitTesting(!viewModel.isLoading)
        .accessibilityIdentifier("SwapInputView.\(viewModel.accessibilityIdentifierTokenPrefix)TokenButton")
    }

    var amountField: some View {
        AmountTextField(
            value: $viewModel.amount,
            isFirstResponder: $viewModel.isFirstResponder,
            textColor: $viewModel.amountTextColor,
            maxFractionDigits: $viewModel.decimalLength,
            moveCursorToTrailingWhenDidBeginEditing: true
        ) { textField in
            textField.font = .font(of: .title1)
            textField.isEnabled = viewModel.isEditable
            textField.placeholder = "0"
            textField.adjustsFontSizeToFitWidth = true
            textField.textAlignment = .right
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("SwapInputView.\(viewModel.accessibilityIdentifierTokenPrefix)Input")
        .if(viewModel.isLoading || viewModel.isAmountLoading) { view in
            HStack {
                Spacer()
                view.skeleton(with: true, size: CGSize(width: 84, height: 20))
            }
        }
        .if(!viewModel.isEditable) { view in
            view.onTapGesture(perform: viewModel.amountFieldTap.send)
        }
        .frame(height: 32)
    }

    var balanceLabel: some View {
        Text("\(L10n.balance) \(viewModel.balanceText)")
            .subtitleStyle()
            .if(viewModel.isLoading) { view in
                view.skeleton(with: true, size: CGSize(width: 84, height: 8))
            }
            .accessibilityIdentifier("SwapInputView.\(viewModel.accessibilityIdentifierTokenPrefix)BalanceLabel")
    }
}

private extension Text {
    func subtitleStyle(color: Color = Color(.silver)) -> some View {
        apply(style: .label1).foregroundColor(color)
    }
}
