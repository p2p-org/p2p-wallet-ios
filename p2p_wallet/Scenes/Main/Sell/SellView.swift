import SwiftUI
import KeyAppUI
import SkeletonUI

struct SellView: View {
    @ObservedObject var viewModel: SellViewModel

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .edgesIgnoringSafeArea(.all)
            VStack {
                switch viewModel.status {
                case .initialized, .updating:
                    loading
                case .ready:
                    if viewModel.isMoreBaseCurrencyNeeded {
                        balanceEmptyErrorView
                    } else if let transaction = viewModel.incompletedTransactions.first,
                              let sellPendingViewModel = viewModel.createSellPendingViewModel(transaction: transaction)
                    {
                        SellPendingView(viewModel: sellPendingViewModel, withNavigationBar: false)
                    } else {
                        SellInputView(viewModel: viewModel)
                    }
                case .error:
                    SellErrorView {
                        viewModel.goBack()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) { Text(L10n.cashOut + " SOL").fontWeight(.semibold) }
        }
        .alert(isPresented: $viewModel.isShowingAlert) {
            Alert(
                title: Text(L10n.areYouSure),
                message: Text(L10n.areYouSureYouWantToInterruptCashOutProcessYourTransactionWonTBeFinished),
                primaryButton: .default(Text(L10n.continueTransaction)),
                secondaryButton: .destructive(Text(L10n.interrupt)) {
                    viewModel.interuptCashOut()
                }
            )
        }
    }

    var balanceEmptyErrorView: some View {
        VStack {
            VStack(spacing: 8) {
                Image(uiImage: UIImage.coins)
                    .padding(.bottom, 12)
                Text(L10n.youNeedALittleMore("SOL"))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .fontWeight(.bold)
                    .apply(style: .title1)
                    .padding(.horizontal, 36)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Text(L10n.theCurrentMinimumAmountIs(viewModel.minBaseAmount.toString(), "SOL"))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .apply(style: .text1)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 80)

            Spacer()

            TextButtonView(
                title: L10n.goToSwap,
                style: .primaryWhite,
                size: .large
            ) { [weak viewModel] in
                viewModel?.goToSwap()
            }
            .frame(height: 56)
        }
        .padding(.bottom, 20)
        .padding(.horizontal, 16)
    }

    var loading: some View {
        VStack(spacing: 8) {
            Text("").frame(height: 44)
                .skeleton(with: true, size: .init(width: CGFloat.infinity, height: 44))
                .shape(type: .rounded(.radius(12, style: .circular)))
            Text("").frame(height: 44).skeleton(with: true, size: .init(width: CGFloat.infinity, height: 44))
                .skeleton(with: true, size: .init(width: CGFloat.infinity, height: 56))
                .shape(type: .rounded(.radius(12, style: .circular)))
            Text("").frame(height: 98).skeleton(with: true, size: .init(width: CGFloat.infinity, height: 98))
                .skeleton(with: true, size: .init(width: CGFloat.infinity, height: 56))
                .shape(type: .rounded(.radius(12, style: .circular)))
            Spacer()
            Text("")
                .padding(.bottom, 60)
                .skeleton(with: true, size: .init(width: CGFloat.infinity, height: 56))
                .shape(type: .rounded(.radius(12, style: .circular)))
                .padding(.bottom, 10)
        }
            .padding(.top, 90)
            .padding(.horizontal, 16)
    }
}
