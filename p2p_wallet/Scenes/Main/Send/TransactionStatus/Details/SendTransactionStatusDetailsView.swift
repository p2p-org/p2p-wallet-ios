import SwiftUI
import KeyAppUI

struct SendTransactionStatusDetailsView: View {

    @ObservedObject private var viewModel: SendTransactionStatusDetailsViewModel

    init(viewModel: SendTransactionStatusDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.title)
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .foregroundColor(Color(Asset.Colors.night.color))

                    Text(viewModel.description)
                        .apply(style: .text3)
                        .foregroundColor(Color(Asset.Colors.night.color))

                    if let fee = viewModel.feeInfo {
                        Text(fee)
                            .apply(style: .text3)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .padding(.all, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundColor(Color(red: 0.804, green: 0.965, blue: 0.804).opacity(0.3))
                                )
                    }
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 24)
            TextButtonView(title: L10n.close, style: .primaryWhite, size: .large, onPressed: viewModel.close.send)
                .frame(height: TextButton.Size.large.height)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .background(
                    Rectangle()
                        .foregroundColor(Color(Asset.Colors.snow.color))
                )
        }
        .navigationTitle(L10n.details)
        .navigationBarHidden(false)
    }
}

struct SendTransactionStatusDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        SendTransactionStatusDetailsView(
            viewModel:
                SendTransactionStatusDetailsViewModel(
                    params: SendTransactionStatusDetailsParameters(
                        title: "This transaction has already been processed",
                        description: "The bank has seen this transaction before. This can occur under normal operation when a UDP packet is duplicated, as a user error from a client not updating its `recent_blockhash`, or as a double-spend attack.",
                        
                        fee: nil
                    )
                )
        )
    }
}
