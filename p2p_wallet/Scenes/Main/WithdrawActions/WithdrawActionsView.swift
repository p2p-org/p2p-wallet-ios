import Combine
import KeyAppUI
import SwiftUI

struct WithdrawActionsView: View {
    @ObservedObject var viewModel: WithdrawActionsViewModel

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .circular)
                .fill(Color(Asset.Colors.rain.color))
                .frame(width: 31, height: 4)
                .padding(.top, 6)
            Text(L10n.withdrawTo)
                .apply(style: .title3, weight: .semibold)
                .padding(.top, 24)
            VStack(spacing: 8) {
                ForEach(viewModel.actions) { item in
                    Button {
                        viewModel.didTapItem(item: item)
                    } label: {
                        cell(item: item)
                    }
                    .disabled(item.isDisabled)
                    .frame(minHeight: 69)
                }
            }
            .padding(.top, 21)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 38)
        .background(Color(Asset.Colors.smoke.color))
        .cornerRadius(20)
    }

    private func foregroundColor(item: WithdrawActionsViewModel.ActionItem) -> Color {
        item.isDisabled ? Color(Asset.Colors.mountain.color) : Color(Asset.Colors.night.color)
    }

    private func cell(item: WithdrawActionsViewModel.ActionItem) -> some View {
        HStack(spacing: 12) {
            Image(uiImage: item.icon)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .apply(style: .text3, weight: .semibold)
                    .foregroundColor(foregroundColor(item: item))

                Text(item.subtitle)
                    .apply(style: .label1, weight: .regular)
                    .foregroundColor(foregroundColor(item: item))
            }
            Spacer()
            if item.isLoading {
                Spinner(
                    color: Color(Asset.Colors.night.color).opacity(0.6),
                    activePartColor: Color(Asset.Colors.night.color)
                )
                .frame(width: 24, height: 24)
            } else {
                Image(uiImage: Asset.MaterialIcon.chevronRight.image)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(16)
    }
}

struct WithdrawActionsView_Previews: PreviewProvider {
    static var previews: some View {
        WithdrawActionsView(viewModel: .init())
    }
}
