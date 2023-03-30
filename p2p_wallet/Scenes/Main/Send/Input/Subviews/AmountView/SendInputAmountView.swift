import KeyAppUI
import SwiftUI

struct SendInputAmountView: View {
    @ObservedObject private var viewModel: SendInputAmountViewModel

    @State private var switchAreaOpacity: Double = 1

    private let mainColor = Asset.Colors.night.color

    init(viewModel: SendInputAmountViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    VStack(spacing: 4) {
                        HStack(spacing: 16) {
                            ZStack(alignment: .leading) {
                                SendInputAmountField(
                                    text: $viewModel.amountText,
                                    isFirstResponder: $viewModel.isFirstResponder,
                                    countAfterDecimalPoint: $viewModel.countAfterDecimalPoint,
                                    textColor: $viewModel.amountTextColor
                                ) { textField in
                                    textField.font = Constants.inputFount
                                    textField.placeholder = "0"
                                    textField.isEnabled = !viewModel.isDisabled
                                }
                                .accessibilityIdentifier("input-amount")

                                if viewModel.isMaxButtonVisible {
                                    TextButtonView(
                                        title: L10n.max.uppercased(),
                                        style: .second,
                                        size: .small,
                                        onPressed: viewModel.maxAmountPressed.send
                                    )
                                    .transition(.opacity.animation(.easeInOut))
                                    .cornerRadius(radius: 32, corners: .allCorners)
                                    .frame(width: 68, height: 28)
                                    .offset(x: viewModel.amountText.isEmpty
                                        ? 16.0
                                        : textWidth(font: Constants.inputFount, text: viewModel.amountText))
                                    .padding(.horizontal, 8)
                                    .accessibilityIdentifier("max-button")
                                }
                            }

                            Text(viewModel.mainTokenText)
                                .foregroundColor(Color(mainColor))
                                .font(uiFont: .systemFont(ofSize: UIFont.fontSize(of: .title2), weight: .bold))
                                .opacity(switchAreaOpacity)
                                .accessibilityIdentifier("current-currency")
                        }
                        if viewModel.showSecondaryAmounts {
                            HStack(spacing: 2) {
                                Text(viewModel.secondaryAmountText)
                                    .foregroundColor(Color(Asset.Colors.mountain.color))
                                    .apply(style: .text4)
                                    .lineLimit(1)
                                Text(viewModel.secondaryCurrencyText)
                                    .foregroundColor(Color(Asset.Colors.mountain.color))
                                    .apply(style: .text4)
                                    .lineLimit(1)
                                Spacer()
                                if viewModel.isSwitchAvailable {
                                    Text(L10n.tapToSwitchTo(viewModel.secondaryCurrencyText))
                                        .foregroundColor(Color(Asset.Colors.mountain.color))
                                        .apply(style: .text4)
                                        .lineLimit(1)
                                        .opacity(switchAreaOpacity)
                                        .layoutPriority(1)
                                }
                            }
                        }
                    }
                    if viewModel.isSwitchAvailable && viewModel.showSecondaryAmounts {
                        Button(
                            action: viewModel.switchPressed.send,
                            label: {
                                Image(uiImage: UIImage.arrowUpDown)
                                    .renderingMode(.template)
                                    .foregroundColor(Color(mainColor))
                                    .frame(width: 16, height: 16)
                                    .opacity(switchAreaOpacity)
                            }
                        )
                        .frame(width: 24, height: 24)
                    }
                }
                .padding(EdgeInsets(top: 21, leading: 24, bottom: 21, trailing: 12))
                .background(RoundedRectangle(cornerRadius: 12))
                .foregroundColor(Color(Asset.Colors.snow.color))
            }
            if viewModel.isSwitchAvailable && viewModel.showSecondaryAmounts {
                tapToSwitchHiddenButton
            }
        }
        .frame(height: 90)
    }

    var tapToSwitchHiddenButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.switchAreaOpacity = 0.3
            }
            self.viewModel.switchPressed.send()
            withAnimation(.easeInOut(duration: 0.3)) {
                self.switchAreaOpacity = 1
            }
        }, label: {
            VStack {}
                .frame(width: 130, height: 90)
        })
        .accessibilityIdentifier("switch-currency")
    }

    func textWidth(font: UIFont, text: String) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return (text as NSString).size(withAttributes: fontAttributes).width
    }
}

struct SendInputAmountView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
            SendInputAmountView(
                viewModel: SendInputAmountViewModel(
                    initialToken: .init(token: .nativeSolana),
                    allowSwitchingMainAmountType: false
                )
            )
            .padding(.horizontal, 16)
        }
    }
}

private enum Constants {
    static let inputFount = UIFont.font(of: .title2, weight: .bold)
}
