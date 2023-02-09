import Combine
import KeyAppUI
import SwiftUI

struct ActionsView: View {
    @ObservedObject var viewModel: ActionsViewModel

    var body: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.actions) { item in
                Button {
                    viewModel.didTapAction(item.id)
                } label: {
                    cell(item: item)
                }
                    .frame(minHeight: 73)
            }
            TextButtonView(
                title: L10n.close,
                style: .second,
                size: .large,
                onPressed: { viewModel.didTapClose() }
            )
                .frame(height: TextButton.Size.large.height)
                .padding(.top, 8)
                .padding(.bottom, 19)
            Spacer()
        }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .background(Color(UIColor.f2F5Fa))
            .cornerRadius(20)
    }

    private func cell(item: ActionViewItem) -> some View {
        HStack(spacing: 16) {
            Image(uiImage: item.icon)
                .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .fontWeight(.bold)
                    .apply(style: .text2)
                    .foregroundColor(Color(Asset.Colors.night.color))

                Text(item.subtitle)
                    .fontWeight(.regular)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()
        }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color(Asset.Colors.snow.color))
            .cornerRadius(16)
    }

}
