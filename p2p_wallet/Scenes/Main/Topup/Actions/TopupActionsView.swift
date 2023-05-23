import Combine
import KeyAppUI
import SwiftUI

struct TopupActionsView: View {
    @ObservedObject var viewModel: TopupActionsViewModel

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .circular)
                .fill(Color(Asset.Colors.rain.color))
                .frame(width: 31, height: 4)
                .padding(.top, 6)
            Text(L10n.topUpYourAccount)
                .fontWeight(.semibold)
                .apply(style: .title3)
                .padding(.top, 22)
                .padding(.bottom, 20)
            ForEach(viewModel.actions) { item in
                Button {
                    viewModel.didTapItem(item: item)
                } label: {
                    cell(item: item)
                }
                    .frame(minHeight: 73)
            }
            Spacer()
        }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
            .background(Color(Asset.Colors.smoke.color))
            .cornerRadius(20)
    }

    private func cell(item: TopupActionsViewModel.ActionItem) -> some View {
        HStack(spacing: 12) {
            Image(uiImage: item.icon)
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .fontWeight(.semibold)
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.night.color))

                Text(item.subtitle)
                    .fontWeight(.regular)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()
        }
            .padding(.all, 16)
            .background(Color(Asset.Colors.snow.color))
            .cornerRadius(16)
    }

}

struct TopupActions_Previews: PreviewProvider {
    static var previews: some View {
        TopupActionsView(viewModel: .init())
    }
}
