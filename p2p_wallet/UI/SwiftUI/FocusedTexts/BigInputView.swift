import SwiftUI
import KeyAppUI

struct BigInputView: View {

    let allButtonPressed: () -> Void
    let amountFieldTap: (() -> Void)?
    let changeTokenPressed: (() -> Void)?
    let accessibilityIdPrefix: String
    let title: String
    let isBalanceVisible: Bool

    @Binding var amount: Double?
    @Binding var amountTextColor: UIColor
    @Binding var isFirstResponder: Bool
    @Binding var decimalLength: Int
    @Binding var isEditable: Bool
    @Binding var balance: Double?
    @Binding var balanceText: String
    @Binding var tokenSymbol: String
    @Binding var isLoading: Bool
    @Binding var isAmountLoading: Bool
    @Binding var fiatAmount: Double?
    @Binding var fiatAmountTextColor: UIColor

    init(
        allButtonPressed: @escaping () -> Void,
        amountFieldTap: (() -> Void)?,
        changeTokenPressed: (() -> Void)?,
        accessibilityIdPrefix: String,
        title: String,
        isBalanceVisible: Bool = true,
        amount: Binding<Double?>,
        amountTextColor: Binding<UIColor> = .constant(Asset.Colors.night.color),
        isFirstResponder: Binding<Bool>,
        decimalLength: Binding<Int>,
        isEditable: Binding<Bool> = .constant(true),
        balance: Binding<Double?> = .constant(nil),
        balanceText: Binding<String> = .constant(""),
        tokenSymbol: Binding<String>,
        isLoading: Binding<Bool> = .constant(false),
        isAmountLoading: Binding<Bool> = .constant(false),
        fiatAmount: Binding<Double?> = .constant(nil),
        fiatAmountTextColor: Binding<UIColor> = .constant(Asset.Colors.silver.color)
    ) {
        self.allButtonPressed = allButtonPressed
        self.amountFieldTap = amountFieldTap
        self.changeTokenPressed = changeTokenPressed
        self.accessibilityIdPrefix = accessibilityIdPrefix
        self.title = title
        self.isBalanceVisible = isBalanceVisible
        self._amount = amount
        self._amountTextColor = amountTextColor
        self._isFirstResponder = isFirstResponder
        self._decimalLength = decimalLength
        self._isEditable = isEditable
        self._balance = balance
        self._balanceText = balanceText
        self._tokenSymbol = tokenSymbol
        self._isLoading = isLoading
        self._isAmountLoading = isAmountLoading
        self._fiatAmount = fiatAmount
        self._fiatAmountTextColor = fiatAmountTextColor
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(title)
                    .subtitleStyle()
                    .accessibilityIdentifier("\(accessibilityIdPrefix)TitleLabel")

                Spacer()

                if isEditable && balance != nil && !isLoading  {
                    allButton
                }
            }
            HStack {
                changeTokenButton
                    .layoutPriority(1)
                amountField
            }
            HStack {
                if isBalanceVisible {
                    balanceLabel
                }

                Spacer()

                if let fiatAmount = fiatAmount, !isLoading, fiatAmount > 0 {
                    Text("≈\(fiatAmount.toString(maximumFractionDigits: 2, roundingMode: .down)) \(Defaults.fiat.code)")
                        .subtitleStyle(color: Color(fiatAmountTextColor))
                        .lineLimit(1)
                        .accessibilityIdentifier("\(accessibilityIdPrefix)FiatLabel")
                }
            }
            .frame(minHeight: 16)
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 12))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(Color(Asset.Colors.snow.color).opacity(isEditable ? 1 : 0.6)))
    }
}

private extension BigInputView {
    var allButton: some View {
        Button(action: allButtonPressed, label: {
            HStack(spacing: 4) {
                Text(L10n.all.uppercaseFirst)
                    .subtitleStyle()
                Text("\(balanceText) \(tokenSymbol)")
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.sky.color))
            }
        })
        .accessibilityIdentifier("\(accessibilityIdPrefix)AllButton")
    }

    var changeTokenButton: some View {
        Button {
            changeTokenPressed?()
        } label: {
            HStack {
                Text(tokenSymbol)
                    .apply(style: .title1)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .if(isLoading) { view in
                        view.skeleton(with: true, size: CGSize(width: 84, height: 20))
                    }

                if changeTokenPressed != nil {
                    Image(uiImage: .expandIcon)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12)
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
            }
        }
        .allowsHitTesting(!isLoading)
        .accessibilityIdentifier("\(accessibilityIdPrefix)TokenButton")
    }

    var amountField: some View {
        AmountTextField(
            value: $amount,
            isFirstResponder: $isFirstResponder,
            textColor: $amountTextColor,
            maxFractionDigits: $decimalLength,
            moveCursorToTrailingWhenDidBeginEditing: true
        ) { textField in
            textField.font = .font(of: .title1)
            textField.isEnabled = isEditable
            textField.placeholder = "0"
            textField.adjustsFontSizeToFitWidth = true
            textField.textAlignment = .right
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("\(accessibilityIdPrefix)Input")
        .if(isLoading || isAmountLoading) { view in
            HStack {
                Spacer()
                view.skeleton(with: true, size: CGSize(width: 84, height: 20))
            }
        }
        .if(!isEditable) { view in
            view.onTapGesture { amountFieldTap?() }
            
        }
        .frame(height: 32)
    }

    var balanceLabel: some View {
        Text("\(L10n.balance) \(balanceText)")
            .subtitleStyle()
            .if(isLoading) { view in
                view.skeleton(with: true, size: CGSize(width: 84, height: 8))
            }
            .accessibilityIdentifier("\(accessibilityIdPrefix)BalanceLabel")
    }
}

private extension Text {
    func subtitleStyle(color: Color = Color(Asset.Colors.silver.color)) -> some View {
        self.apply(style: .label1).foregroundColor(color)
    }
}
