//
//  BuyInputOutputView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.09.2022.
//

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
                        .padding(.trailing, 4)

                    currency(value: leftSubtitle) { onTap(.left) }
                        .lineLimit(1)
                        .padding(.trailing, 20)
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
                        side: .right
                    )
                        .padding(.leading, 8)
                        .padding(.trailing, 4)

                    currency(value: rightSubtitle) {}
                        .lineLimit(1)
                        .padding(.trailing, 30)
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
        }.frame(height: 60)
            .background(Color(Asset.Colors.cloud.color))
            .cornerRadius(16)
            .overlay(Text("\(fontSynchorinze.font)").apply(style: .text4).offset(x: 0, y: 50))
    }

    func currency(value: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(value)
                    .font(uiFont: fontSynchorinze.font)
                    .foregroundColor(Color(Asset.Colors.night.color.withAlphaComponent(0.3)))
                    .fixedSize(horizontal: true, vertical: false)
                Image(uiImage: Asset.MaterialIcon.arrowDropDown.image)
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
        }
    }
}

private class FontSynchorinze: ObservableObject {
    static let defaultFont: UIFont = UIFont.font(of: .title2)
    static let maxFontSize: CGFloat = 22
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
                let rightTotal = 50 + rightTitleSize.width + 4 + rightSubTitleSize.width + 30

                print(leftTitle, leftSubtitle, rightTitle, rightSubTitle)
                print(leftTitleSize, rightTitleSize)
                print(leftTotal, rightTotal, width / 2)

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

    func makeUIView(context ctx: Context) -> UITextField {
        let textField = UITextField()

        textField.font = fontSynchorinze.font
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.delegate = ctx.coordinator
        ctx.coordinator.adjustFont(textField)
        textField.font = fontSynchorinze.font
        textField.textAlignment = .right
        textField.text = text
        textField.addTarget(ctx.coordinator, action: #selector(ctx.coordinator.textDidChanged), for: .editingChanged)

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
            text = textField.text ?? ""
            // adjustFont(textField)
        }

        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            let endPosition = textField.endOfDocument
            textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
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

            let size = text.size(withAttributes: [.font: FontSynchorinze.defaultFont.withSize(minFontSizeValue)])

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
            Color(Asset.Colors.lime.color)
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
