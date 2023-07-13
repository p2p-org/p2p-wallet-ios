import Combine
import KeyAppUI
import SwiftUI

private enum Constants {
    static let verticalSpacing: CGFloat = 32
    static let verticalPadding: CGFloat = 16
    static let imageRightSpacing: CGFloat = 16
    static let contentHorizontalSpacing: CGFloat = 16
    static let imageSize: CGFloat = 48
    static let textSpacing: CGFloat = 2
    static let textHStackSpacing: CGFloat = 4
    static let infoHeight: CGFloat = 14
}

struct SendTransactionDetailView: View {
    @ObservedObject private var viewModel: SendTransactionDetailViewModel

    init(viewModel: SendTransactionDetailViewModel) { self.viewModel = viewModel }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            ForEach(viewModel.cellModels) { model in
                cellView(model: model)
                    .onLongPressGesture(perform: { viewModel.longTapped.send(model) })
            }
            Button(
                action: {
                    viewModel.cancelSubject.send()
                },
                label: {
                    Text(L10n.cancel)
                        .foregroundColor(Color(.night))
                        .font(uiFont: .font(of: .text1, weight: .bold))
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(Color(.rain))
                        .cornerRadius(12)
                }
            )
        }
        .padding(.top, 20)
        .padding(.vertical, Constants.verticalPadding)
        .padding(.horizontal, Constants.contentHorizontalSpacing)
        .sheetHeader(title: L10n.transactionDetails, withSeparator: false)
    }

    private func cellView(model: SendTransactionDetailViewModel.CellModel) -> some View {
        HStack(spacing: Constants.imageRightSpacing) {
            Image(model.image)
                .frame(width: Constants.imageSize, height: Constants.imageSize)
            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Button(
                    action: {
                        model.info?()
                    },
                    label: {
                        HStack(spacing: Constants.textHStackSpacing) {
                            Text(model.title)
                                .lineLimit(1)
                                .foregroundColor(Color(.night))
                                .font(uiFont: .font(of: .text1, weight: .semibold))
                            if model.info != nil {
                                Image(uiImage: .init(resource: .feeInfo).withRenderingMode(.alwaysOriginal))
                                    .resizable()
                                    .frame(
                                        width: Constants.infoHeight,
                                        height: Constants.infoHeight
                                    )
                            }
                        }
                    }
                ).allowsHitTesting(model.info != nil)

                HStack(spacing: Constants.textHStackSpacing) {
                    if model.isLoading {
                        Text(L10n.loading)
                            .apply(style: .text4)
                            .foregroundColor(Color(.sky))
                        CircularProgressIndicatorView(
                            backgroundColor: .init(resource: .sky).withAlphaComponent(0.6),
                            foregroundColor: .init(resource: .sky)
                        )
                        .frame(width: 16, height: 16)
                    } else {
                        VStack(alignment: .leading) {
                            ForEach(model.subtitle, id: \.0) { subtitle in
                                HStack {
                                    Text(subtitle.0)
                                        .foregroundColor(Color(model.isFree ? .mint : .night))
                                        .font(uiFont: .font(of: .label1, weight: model.isFree ? .semibold : .regular))
                                        .fixedSize(horizontal: false, vertical: true)
                                    if let additionalText = subtitle.1 {
                                        Text("(\(additionalText))")
                                            .foregroundColor(Color(.mountain))
                                            .font(uiFont: .font(of: .label1))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// struct SendTokenDetails_Previews: PreviewProvider {
//     static var previews: some View {
//         SendTransactionDetailView(model: SendTransactionDetailView.Model(
//             recipientAddress: "2PfZSWbqREfwGzWESqZ1quaMHXsb67Q4cbYuaY6yQxfS",
//             recipientAmount: "10 USDC",
//             recipientAmountUsd: "$10",
//             transactionFee: "Free (99 left for today)",
//             accountCreationFee: "0.028813 USDC",
//             accountCreationFeeUsd: "$0.03",
//             total: "10.028813 USDC",
//             totalUsd: "$10.02"
//         ))
//     }
// }
