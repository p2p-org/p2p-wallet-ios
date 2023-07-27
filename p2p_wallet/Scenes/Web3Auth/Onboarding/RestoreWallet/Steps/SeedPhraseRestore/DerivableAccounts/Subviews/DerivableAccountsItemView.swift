import SolanaSwift
import SwiftUI

struct DerivableAccountsItemView: View {
    private let nativeToken: TokenMetadata
    private let address: String
    private let balanceInFiat: String
    private let balance: String

    init(account: DerivableAccount) {
        nativeToken = .nativeSolana
        address = account.info.publicKey.short()
        balanceInFiat = (account.amount * account.price).formattedFiat(roundingMode: .down)
        balance = account.amount?.tokenAmountFormattedString(
            symbol: nativeToken.symbol,
            maximumFractionDigits: Int(nativeToken.decimals)
        ) ?? ""
    }

    var body: some View {
        HStack(spacing: 12) {
            CoinLogoImageViewRepresentable(size: 48, args: .token(nativeToken))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(nativeToken.symbol)
                    .apply(style: .text2)
                    .foregroundColor(Color(.night))

                Text(address)
                    .apply(style: .label1)
                    .foregroundColor(Color(.mountain))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(balanceInFiat)
                    .apply(style: .text2)
                    .foregroundColor(Color(.night))

                Text(balance)
                    .apply(style: .label1)
                    .foregroundColor(Color(.mountain))
            }
        }
        .background(Color(.snow))
    }
}
