import Send
import SwiftUI

struct WormholeSendFeesView: View {
    @ObservedObject var viewModel: WormholeSendFeesViewModel

    var body: some View {
        VStack {
            HandleBarView()
                .padding(.vertical, 6)

            Text(L10n.transactionDetails)
                .fontWeight(.semibold)
                .apply(style: .text1)
                .padding(.bottom, 20)

            ForEach(viewModel.fees) { fee in
                VStack(alignment: .leading, spacing: 4) {
                    Text(fee.title)
                        .apply(style: .text3)
                        .foregroundColor(Color(.night))
                    HStack {
                        Text(fee.subtitle)
                            .apply(style: .label1)
                            .foregroundColor(
                                fee.isFree ? Color(.mint)
                                    : Color(.mountain)
                            )
                        Spacer()
                        Text(fee.detail)
                            .apply(style: .label1)
                            .foregroundColor(Color(.mountain))
                    }
                }
                .frame(height: 64)
            }
            .padding(.horizontal, 16)

            Button(action: {
                viewModel.close.send()
            }, label: {
                Text(L10n.okay)
                    .font(uiFont: .font(of: .text2, weight: .semibold))
                    .foregroundColor(Color(.night))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(.rain))
                    .cornerRadius(12)
            })
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { (_) in
            UIApplication.shared.keyWindow?.endEditing(true)
        }
    }
}

struct WormholeSendFeesView_Previews: PreviewProvider {
    static var fees: [WormholeSendFees] = [
        .init(
            title: "Recipient’s address",
            subtitle: "0x0ea9f413a9be5afcec51d1bc8fd20b29bef5709c",
            detail: nil
        ),
        .init(title: "Network Fees", subtitle: "0.003 WETH", detail: "$ 3.31"),
        .init(title: "Using Wormhole bridge", subtitle: "0.0005 SOL", detail: "$ 0.05"),
        .init(title: "Total", subtitle: "0.0005 SOL\n0.009 ETH", detail: "$ 0.05"),
    ].compactMap { $0 }

    static var previews: some View {
        WormholeSendFeesView(
            viewModel: .init(fees: fees)
        )
    }
}
