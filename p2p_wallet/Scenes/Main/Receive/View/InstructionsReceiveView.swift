import KeyAppUI
import SwiftUI

// MARK: - InstructionsReceiveCellView

struct InstructionsReceiveView: View {
    var item: InstructionsReceiveCellItem

    var body: some View {
        VStack {
            ForEach(item.instructions, id: \.0) { instruction in
                HStack(spacing: 10) {
                    Text(instruction.0)
                        .fontWeight(.semibold)
                        .apply(style: .label1)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(Asset.Colors.mountain.color), lineWidth: 1)
                        )

                    Text(instruction.1)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .apply(style: .text3)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            Text(item.tip)
                .apply(style: .text4)
                .foregroundColor(Color(Asset.Colors.mountain.color))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(radius: 16, corners: .allCorners)
    }
}

struct InstructionsReceiveCellView_Previews: PreviewProvider {
    static var previews: some View {
        InstructionsReceiveView(item: .init(instructions: [("1", "text1"), ("2", "text2"), ("3", "text3")], tip: "some bottom text"))
    }
}
