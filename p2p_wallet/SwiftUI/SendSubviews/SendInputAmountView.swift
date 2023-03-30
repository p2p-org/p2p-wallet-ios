import Combine
import KeyAppUI
import SwiftUI

struct SendInputAmountView: View {
    @Binding var amountText: String
    @Binding var isFirstResponder: Bool
    let amountTextColor: UIColor
    let countAfterDecimalPoint: Int
    let isDisabled: Bool
    let isMaxButtonVisible: Bool
    let mainTokenText: String
    let secondaryAmountText: String
    let secondaryCurrencyText: String
    let isSwitchMainAmountTypeAvailable: Bool
    let maxAmountPressed: PassthroughSubject<Void, Never>
    let switchPressed: PassthroughSubject<Void, Never>

    @State private var switchAreaOpacity: Double = 1

    init(
        amountText: Binding<String>,
        isFirstResponder: Binding<Bool>,
        amountTextColor: UIColor,
        countAfterDecimalPoint: Int,
        mainTokenText: String,
        secondaryAmountText: String,
        secondaryCurrencyText: String,
        maxAmountPressed: PassthroughSubject<Void, Never>,
        switchPressed: PassthroughSubject<Void, Never>,
        isDisabled: Bool = false,
        isMaxButtonVisible: Bool = true,
        isSwitchMainAmountTypeAvailable: Bool = true
    ) {
        _amountText = amountText
        _isFirstResponder = isFirstResponder
        self.amountTextColor = amountTextColor
        self.countAfterDecimalPoint = countAfterDecimalPoint
        self.isDisabled = isDisabled
        self.isMaxButtonVisible = isMaxButtonVisible
        self.mainTokenText = mainTokenText
        self.secondaryAmountText = secondaryAmountText
        self.secondaryCurrencyText = secondaryCurrencyText
        self.isSwitchMainAmountTypeAvailable = isSwitchMainAmountTypeAvailable
        self.maxAmountPressed = maxAmountPressed
        self.switchPressed = switchPressed
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    VStack(spacing: 4) {
                        HStack(spacing: 16) {
                            ZStack(alignment: .leading) {
                                SendInputAmountField(
                                    text: $amountText,
                                    isFirstResponder: $isFirstResponder,
                                    textColor: amountTextColor,
                                    countAfterDecimalPoint: countAfterDecimalPoint
                                ) { textField in
                                    textField.font = Constants.inputFount
                                    textField.placeholder = "0"
                                    textField.isEnabled = !isDisabled
                                }
                                .accessibilityIdentifier("input-amount")

                                if isMaxButtonVisible {
                                    TextButtonView(
                                        title: L10n.max.uppercased(),
                                        style: .second,
                                        size: .small,
                                        onPressed: maxAmountPressed.send
                                    )
                                    .transition(.opacity.animation(.easeInOut))
                                    .cornerRadius(radius: 32, corners: .allCorners)
                                    .frame(width: 68, height: 28)
                                    .offset(x: amountText.isEmpty
                                        ? 16.0
                                        : textWidth(font: Constants.inputFount, text: amountText))
                                    .padding(.horizontal, 8)
                                    .accessibilityIdentifier("max-button")
                                }
                            }

                            Text(mainTokenText)
                                .foregroundColor(Color(Constants.mainColor))
                                .font(uiFont: .systemFont(ofSize: UIFont.fontSize(of: .title2), weight: .bold))
                                .opacity(switchAreaOpacity)
                                .accessibilityIdentifier("current-currency")
                        }

                        if isSwitchMainAmountTypeAvailable {
                            HStack(spacing: 2) {
                                Text(secondaryAmountText)
                                    .secondaryStyle()

                                Text(secondaryCurrencyText)
                                    .secondaryStyle()

                                Text(L10n.tapToSwitchTo(secondaryCurrencyText))
                                    .secondaryStyle()
                                    .opacity(switchAreaOpacity)
                                    .layoutPriority(1)
                            }
                        }
                    }
                    if isSwitchMainAmountTypeAvailable {
                        Button(
                            action: switchPressed.send,
                            label: {
                                Image(uiImage: UIImage.arrowUpDown)
                                    .renderingMode(.template)
                                    .foregroundColor(Color(Constants.mainColor))
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
            if isSwitchMainAmountTypeAvailable {
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
            self.switchPressed.send()
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
                amountText: .constant(""),
                isFirstResponder: .constant(true),
                amountTextColor: .black,
                countAfterDecimalPoint: 9,
                mainTokenText: "SOL",
                secondaryAmountText: "0",
                secondaryCurrencyText: "USD",
                maxAmountPressed: .init(),
                switchPressed: .init()
            )
            .padding(.horizontal, 16)
        }
    }
}

private enum Constants {
    static let inputFount = UIFont.font(of: .title2, weight: .bold)
    static let mainColor = Asset.Colors.night.color
}

private extension Text {
    func secondaryStyle() -> some View {
        foregroundColor(Color(Asset.Colors.mountain.color))
            .apply(style: .text4)
            .lineLimit(1)
    }
}
