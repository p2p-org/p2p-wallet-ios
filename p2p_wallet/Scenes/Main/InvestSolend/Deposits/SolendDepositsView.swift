import KeyAppUI
import Resolver
import SolanaSwift
import Solend
import SwiftUI

struct SolendDepositsView: View {
    @StateObject var viewModel: SolendDepositsViewModel

    var body: some View {
        ScrollView {
            VStack {
                content
                    .padding(.horizontal, 8)
                Spacer()
            }
            .padding(.top, 10)
            .listStyle(.plain)
        }.onAppear {
            UITableView.appearance().separatorStyle = .none
            UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
            UINavigationBar.appearance().shadowImage = UIImage()
        }
        .navigationTitle("\(L10n.yourDeposits) (\(viewModel.deposits.count))")
        .navigationBarTitleDisplayMode(.inline)
    }

    var content: some View {
        ForEach(viewModel.deposits, id: \.self) { deposit in
            SolendDepositView(
                item: deposit,
                onDepositTapped: { [weak viewModel] in
                    viewModel?.depositTapped(item: deposit)
                }, onWithdrawTapped: { [weak viewModel] in
                    viewModel?.withdrawTapped(item: deposit)
                }
            )
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct SolendDepositsView_Previews: PreviewProvider {
    static var previews: some View {
        SolendDepositsView(viewModel: .init(dataService: SolendDataServiceMock()))
    }
}
