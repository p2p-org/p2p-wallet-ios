import KeyAppUI
import SwiftUI

enum BuyInputOutputActiveSide {
    case left
    case right
    case none
}

struct BuyInputOutputView: View {
    @Binding var leftTitle: String
    let leftSubtitle: String

    @Binding var rightTitle: String
    let rightSubtitle: String

    @Binding var activeSide: BuyInputOutputActiveSide

    let onTap: (BuyInputOutputActiveSide) -> Void

    @StateObject private var fontSynchorinze: FontSynchorinze = .init()

    var body: some View {
        GeometryReader { reader in
            HStack(spacing: 0) {
                // Left input

                HStack {
                    TextfieldView(
                        text: $leftTitle,
                        activeSide: $activeSide,
                        fontSynchorinze: fontSynchorinze,
                        font: fontSynchorinze.font,
                        side: .left
                    )
                        .padding(.leading, 8)
                        .accessibilityIdentifier("BuyInputOutputView.leftInput")

                    currency(value: leftSubtitle) { onTap(.left) }
                        .lineLimit(1)
                        .padding(.trailing, 20)
                        .accessibilityIdentifier("BuyInputOutputView.leftCurrency")
                }.frame(width: reader.size.width / 2)

                // Divider
                Divider()

                // Right input
                HStack {
                    TextfieldView(
                        text: $rightTitle,
                        activeSide: $activeSide,
                        fontSynchorinze: fontSynchorinze,
                        font: fontSynchorinze.font,
                        side: .right,
                        isFocued: false
                    )
                        .padding(.leading, 8)
                        .accessibilityIdentifier("BuyInputOutputView.rightInput")

                    currency(value: rightSubtitle) { onTap(.right) }
                        .lineLimit(1)
                        .padding(.trailing, 20)
                        .accessibilityIdentifier("BuyInputOutputView.rightCurrency")
                }.frame(width: reader.size.width / 2)
            }
            .onAppear {
                fontSynchorinze.apply(
                    leftTitle: leftTitle,
                    leftSubtitle: leftSubtitle,
                    rightTitle: rightTitle,
                    rightSubTitle: rightSubtitle,
                    width: reader.size.width
                )
            }
            .onChange(of: leftTitle) { newValue in fontSynchorinze.apply(
                leftTitle: newValue,
                leftSubtitle: leftSubtitle,
                rightTitle: rightTitle,
                rightSubTitle: rightSubtitle,
                width: reader.size.width
            ) }
            .onChange(of: rightTitle) { newValue in fontSynchorinze.apply(
                leftTitle: leftTitle,
                leftSubtitle: leftSubtitle,
                rightTitle: newValue,
                rightSubTitle: rightSubtitle,
                width: reader.size.width
            ) }
        }.frame(height: 62)
            .background(Color(.cloud))
            .cornerRadius(12)
        // .overlay(Text("\(fontSynchorinze.font)").apply(style: .text4).offset(x: 0, y: 50))
    }

    func currency(value: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(value)
                    .font(uiFont: fontSynchorinze.font)
                    .foregroundColor(Color(.night).opacity(0.3))
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.trailing, 8)
                Image(uiImage: Asset.MaterialIcon.arrowDropDown.image)
                    .frame(width: 7, height: 4)
                    .foregroundColor(Color(.night))
            }
        }
    }
}

private class FontSynchorinze: ObservableObject {
    static let defaultFont: UIFont = UIFont.font(of: .title2)
    static let maxFontSize: CGFloat = 28
    static let minFontSize: CGFloat = 10

    var leftFontSize: CGFloat = FontSynchorinze.maxFontSize { didSet { recalculate() } }
    var rightFontSize: CGFloat = FontSynchorinze.maxFontSize { didSet { recalculate() } }

    @Published var font: UIFont = FontSynchorinze.defaultFont

    func apply(
        leftTitle: String,
        leftSubtitle: String,
        rightTitle: String,
        rightSubTitle: String,
        width: CGFloat
    ) {
        func minFontSize() -> CGFloat? {
            for fontSize in stride(
                from: FontSynchorinze.maxFontSize,
                through: FontSynchorinze.minFontSize,
                by: -1
            ) {
                let leftTitleSize = leftTitle
                    .size(withAttributes: [.font: FontSynchorinze.defaultFont.withSize(fontSize)])
                let leftSubtitleSize = leftSubtitle
                    .size(withAttributes: [.font: FontSynchorinze.defaultFont.withSize(fontSize)])
                let rightTitleSize = rightTitle
                    .size(withAttributes: [.font: FontSynchorinze.defaultFont.withSize(fontSize)])
                let rightSubTitleSize = rightSubTitle
                    .size(withAttributes: [.font: FontSynchorinze.defaultFont.withSize(fontSize)])

                let leftTotal = 50 + leftTitleSize.width + 4 + leftSubtitleSize.width + 20
                let rightTotal = 50 + rightTitleSize.width + 4 + rightSubTitleSize.width + 20
//
//                print(leftTitle, leftSubtitle, rightTitle, rightSubTitle)
//                print(leftTitleSize, rightTitleSize)
//                print(leftTotal, rightTotal, width / 2)

                if leftTotal < (width / 2), rightTotal < (width / 2) { return fontSize }
            }
            return nil
        }

        let minFontSizeValue = minFontSize() ?? FontSynchorinze.minFontSize
        font = FontSynchorinze.defaultFont.withSize(minFontSizeValue)
    }

    func recalculate() {
        // // let minFontSize = min(leftFontSize, rightFontSize)
        // font = font.withSize(minFontSize)
    }
}

/// Special text field for input
/// Font will be synchronize between textfields
private struct TextfieldView: UIViewRepresentable {
    @Binding var text: String
    @Binding var activeSide: BuyInputOutputActiveSide
    let fontSynchorinze: FontSynchorinze
    let font: UIFont
    let side: Side
    var isFocued: Bool = false

    func makeUIView(context ctx: Context) -> UITextField {
        let textField = UITextField()

        textField.font = fontSynchorinze.font
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.delegate = ctx.coordinator
        ctx.coordinator.adjustFont(textField)
        textField.font = fontSynchorinze.font
        textField.textAlignment = .right
        textField.text = text
        textField.keyboardType = .decimalPad
        textField.addTarget(ctx.coordinator, action: #selector(ctx.coordinator.textDidChanged), for: .editingChanged)
        if isFocued {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                textField.becomeFirstResponder()
            }
        }
        return textField
    }

    func updateUIView(_ textField: UITextField, context ctx: Context) {
        textField.text = text
        ctx.coordinator.adjustFont(textField)
        textField.font = fontSynchorinze.font
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, activeSide: $activeSide, fontSynchorinze: fontSynchorinze, side: side)
    }

    enum Side {
        case left
        case right
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var activeSide: BuyInputOutputActiveSide
        let fontSynchorinze: FontSynchorinze
        let side: Side

        init(
            text: Binding<String>,
            activeSide: Binding<BuyInputOutputActiveSide>,
            fontSynchorinze: FontSynchorinze,
            side: Side
        ) {
            _text = text
            _activeSide = activeSide
            self.fontSynchorinze = fontSynchorinze
            self.side = side
        }

        @objc func textDidChanged(_ textField: UITextField) {
            if activeSide == .right {
                text = (textField.text ?? "").fiatFormat
            } else if activeSide == .left {
                text = (textField.text ?? "").moonpayCryptocurrencyFormat
            } else {
                text = textField.text ?? ""
            }
            // adjustFont(textField)
        }

        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            // uncomment if you'd like to put cursor to the end of the field
//            DispatchQueue.main.async {
//                let endPosition = textField.endOfDocument
//                textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
//            }
            return true
        }

        func textFieldDidBeginEditing(_: UITextField) {
            switch side {
            case .left: activeSide = .left
            case .right: activeSide = .right
            }
        }

        func textFieldDidEndEditing(_: UITextField) {
            activeSide = .none
        }

        func adjustFont(_ textField: UITextField) {
            let text = NSString(string: textField.text ?? "")

            func minFontSize() -> CGFloat? {
                for fontSize in stride(
                    from: FontSynchorinze.maxFontSize,
                    through: FontSynchorinze.minFontSize,
                    by: -0.5
                ) {
                    let size = text.size(withAttributes: [.font: FontSynchorinze.defaultFont.withSize(fontSize)])

                    if size.width + 10 < textField.frame.width { return fontSize }
                }
                return nil
            }

            let minFontSizeValue = minFontSize() ?? FontSynchorinze.minFontSize

//            let size = text.size(withAttributes: [.font: FontSynchorinze.defaultFont.withSize(minFontSizeValue)])
            // print("Here: \(side) \(minFontSizeValue) \(size.width) \(textField.frame.width)")
            switch side {
            case .left: fontSynchorinze.leftFontSize = minFontSizeValue
            case .right: fontSynchorinze.rightFontSize = minFontSizeValue
            }
        }
    }
}

struct BuyInputOutputView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.lime)
            BuyInputOutputView(
                leftTitle: .constant("12"),
                leftSubtitle: "SOL",
                rightTitle: .constant("500"),
                rightSubtitle: "USD",
                activeSide: .constant(.none)
            ) { _ in }
        }
    }
}

private extension String {
    var moonpayCryptocurrencyFormat: String {
        formatToMoneyFormat(decimalSeparator: ".", maxDecimals: 2)
    }
}
