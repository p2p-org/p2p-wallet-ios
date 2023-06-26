import SwiftUI

struct SentViaLinkHistoryTransactionView: View {
    // MARK: - Properties

    let transaction: SendViaLinkTransactionInfo

    // MARK: - Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(.sendViaLinkCircleCompleted)
                .resizable()
                .frame(width: 48, height: 48)
            
            Text(L10n.sentViaOneTimeLink)
                .fontWeight(.semibold)
                .apply(style: .text3)
                .layoutPriority(1)
            
            Spacer(minLength: 0)
            
            Text(transaction.amount.tokenAmountFormattedString(
                symbol: transaction.token.symbol,
                maximumFractionDigits: Int(transaction.token.decimals)
            ))
            .fontWeight(.semibold)
            .apply(style: .text3)
            .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#if DEBUG
struct SentViaLinkHistoryTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        SentViaLinkHistoryTransactionView(
            transaction: Array<SendViaLinkTransactionInfo>.mocked.first!
        )
    }
}
#endif
