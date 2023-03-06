import SwiftUI
import KeyAppUI

// MARK: - ListRowReceiveCellView

/// Receive List row cell
struct ListRowReceiveCellView: View {
    var item: ListRowReceiveCellItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.title)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .fontWeight(.semibold)
                    .apply(style: .text2)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack {
                Text(item.description)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .apply(style: .text4)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
            .padding(.horizontal, 20)
            .padding(.top, item.showTopCorners ? 16 : 8)
            .padding(.bottom, item.showBottomCorners ? 16 : 8)
            .background(Color(Asset.Colors.snow.color))
            .cornerRadius(radius: item.showTopCorners ? 16 : 0, corners: .topLeft)
            .cornerRadius(radius: item.showTopCorners ? 16 : 0, corners: .topRight)
            .cornerRadius(radius: item.showBottomCorners ? 16 : 0, corners: .bottomLeft)
            .cornerRadius(radius: item.showBottomCorners ? 16 : 0, corners: .bottomRight)
    }
}

struct ListRowReceiveCellView_Previews: PreviewProvider {
    static var previews: some View {
        ListRowReceiveCellView(item: .init(
            id: "1",
            title: "2",
            description: "desc",
            showTopCorners: true,
            showBottomCorners: true)
        )
    }
}

// MARK: - ListDividerReceiveCellView

struct ListDividerReceiveCellView: View {
    var body: some View {
        Color(Asset.Colors.rain.color)
            .padding(.leading, 20)
            .frame(height: 1)
    }
}

struct ListDividerReceiveCellView_Previews: PreviewProvider {
    static var previews: some View {
        ListDividerReceiveCellView()
    }
}

// MARK: - SpacerReceiveCellView


struct SpacerReceiveCellView: View {
    var body: some View {
        Color(UIColor.clear)
            .frame(height: 8)
    }
}

// MARK: - RefundBannerReceiveCellView

struct RefundBannerReceiveCellView: View {
    var item: RefundBannerReceiveCellItem

    var body: some View {
        HStack {
            Text(item.text)
                .foregroundColor(Color(Asset.Colors.night.color))
                .fontWeight(.semibold)
                .apply(style: .text2)
                .multilineTextAlignment(.leading)
            Image(uiImage: .receiveBills)
        }
        .padding(.horizontal, 20)
        .background(Color(UIColor.cdf6cd))
        .cornerRadius(radius: 16, corners: .allCorners)
    }
}

struct RefundBannerReceiveCellView_Previews: PreviewProvider {
    static var previews: some View {
        RefundBannerReceiveCellView(item: .init(text: "Some banner text"))
    }
}

// MARK: - InstructionsReceiveCellView

struct InstructionsReceiveCellView: View {
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
        InstructionsReceiveCellView(item: .init(instructions: [("1", "text1"), ("2", "text2"), ("3", "text3")], tip: "some bottom text"))
    }
}
