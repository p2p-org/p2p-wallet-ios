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

struct SolendDepositView: View {
    let item: SolendUserDepositItem
    let onDepositTapped: () -> Void
    let onWithdrawTapped: () -> Void

    init(
        item: SolendUserDepositItem,
        onDepositTapped: @escaping () -> Void,
        onWithdrawTapped: @escaping () -> Void
    ) {
        self.item = item
        self.onDepositTapped = onDepositTapped
        self.onWithdrawTapped = onWithdrawTapped
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            info
            buttons
        }
        .padding(16)
        .background(Color(Asset.Colors.cloud.color))
        .cornerRadius(20)
    }

    var info: some View {
        HStack(spacing: 12) {
            if let logo = item.logo, let url = URL(string: logo) {
                ImageView(withURL: url)
                    .clipShape(Circle())
                    .frame(width: 48, height: 48)
            } else {
                Circle()
                    .fill(Color(Asset.Colors.mountain.color))
                    .frame(width: 48, height: 48)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .apply(style: .text2)
                Text(item.subtitle)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .apply(style: .label1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Text(item.rightTitle)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text2, weight: .semibold))
            }
        }
        .frame(height: 64)
    }

    var buttons: some View {
        HStack(spacing: 8) {
            Button(
                action: {
                    onDepositTapped()
                },
                label: {
                    Text(L10n.addMore)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.rain.color))
                        .cornerRadius(12)
                }
            )
            Button(
                action: {
                    onWithdrawTapped()
                },
                label: {
                    Text(L10n.withdraw)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.rain.color))
                        .cornerRadius(12)
                }
            )
        }
    }
}

struct SolendUserDepositItem: Hashable {
    var id: String
    var logo: String?
    var title: String
    var subtitle: String
    var rightTitle: String
}
