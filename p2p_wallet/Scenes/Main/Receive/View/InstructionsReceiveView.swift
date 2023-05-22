import KeyAppUI
import SwiftUI

// MARK: - InstructionsReceiveCellView

struct InstructionsReceiveView: View {
    var item: InstructionsReceiveCellItem

    static let textHorizontalSpacing: CGFloat = 15
    static let numberSize: CGFloat = 21

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(item.instructions, id: \.0) { instruction in
                instructionCell(instruction: instruction)
            }
            if let tip = item.tip {
                HStack(alignment: .top, spacing: InstructionsReceiveView.textHorizontalSpacing) {
                    // Hiddenp2p_wallet/Resources/vi.lproj/Localizable.strings element, to save space
                    Text("0")
                        .frame(
                            width: InstructionsReceiveView.numberSize,
                            height: InstructionsReceiveView.numberSize
                        )
                        .opacity(0)
                    
                    Text(tip)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 16)
                }
            }
            Spacer()
        }
        .padding(.top, 24)
        .padding(.horizontal, 15)
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(radius: 16, corners: .allCorners)
        .fixedSize(horizontal: false, vertical: true)
    }

    func instructionCell(instruction: (String, (String, String))) -> some View {
        HStack(alignment: .top, spacing: InstructionsReceiveView.textHorizontalSpacing) {
            VStack(alignment: .center, spacing: 2) {
                Text(instruction.0)
                    .fontWeight(.semibold)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.silver.color))
                    .frame(
                        width: InstructionsReceiveView.numberSize,
                        height: InstructionsReceiveView.numberSize
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.5)
                            .stroke(Color(Asset.Colors.silver.color), lineWidth: 1.5)
                    )

                Color(Asset.Colors.silver.color)
                    .frame(width: 1)
                    .padding(.bottom, 2)
                    .if(instruction.0 == item.instructions.last?.0) { view in
                        view.opacity(0)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(instruction.1.0)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .apply(style: .text3)
                    .multilineTextAlignment(.leading)
                Text(instruction.1.1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .apply(style: .text4)
                    .multilineTextAlignment(.leading)
            }
            .padding(.bottom, instruction.0 == item.instructions.last?.0 ? 0 : 10)
        }
    }

}

struct InstructionsReceiveCellView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            InstructionsReceiveView(item: .init(
                instructions: [
                    ("1", ("We bridge to Solana", "One twot")),
                    ("2", ("Send USDC to your Ethereum account", "One two")),
                    ("3", ("text3", "One two"))],
                tip: "You need only to sign a transaction"))
            Spacer()
        }
    }
}
