import SwiftUI

struct SellTransactionDetailsInfoView: View {
    let viewModel: SellTransactionDetailsInfoModel
    let helpAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(viewModel.icon)
                .renderingMode(.template)
                .foregroundColor(viewModel.iconColor)
            switch viewModel.text {
            case let .raw(text):
                Text(text)
                    .foregroundColor(viewModel.textColor)
                    .apply(style: .text3)
                    .fixedSize(horizontal: false, vertical: true)
            case let .help(text):
                Text(text)
                    .onTapGesture(perform: helpAction)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(viewModel.backgroundColor)
        .cornerRadius(12)
    }
}
