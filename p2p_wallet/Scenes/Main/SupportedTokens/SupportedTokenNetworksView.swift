import KeyAppUI
import SwiftUI
import AnalyticsManager
import Resolver

struct SupportedTokenNetworksView: View {
    @Injected private var analyticsManager: AnalyticsManager
    
    let item: SupportedTokenItem
    let onTap: (SupportedTokenItemNetwork?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .circular)
                .fill(Color(Asset.Colors.silver.color))
                .frame(width: 31, height: 4)
                .padding(.top, 6)

            Text(L10n.chooseNetwork)
                .fontWeight(.semibold)
                .apply(style: .text1)
                .padding(.top, 18)
                .padding(.bottom, 28)

            VStack(spacing: 8) {
                ForEach(item.availableNetwork) { network in
                    switch network {
                    case .solana:
                        self.network(icon: .solanaIcon, title: "Solana") {
                            onTap(.solana)
                            analyticsManager.log(event: .receiveNetworkClickButton(network: network.analyticsName()))
                        }
                    case .ethereum:
                        self.network(icon: .ethereumIcon, title: "Ethereum") {
                            onTap(.ethereum)
                            analyticsManager.log(event: .receiveNetworkClickButton(network: network.analyticsName()))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            TextButtonView(title: L10n.close, style: .second, size: .large) {
                onTap(nil)
            }
            .frame(height: TextButton.Size.large.height)
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(
            Color(Asset.Colors.smoke.color)
                .ignoresSafeArea()
                .cornerRadius(radius: 16, corners: [.topLeft, .topRight])
        )
        .onAppear {
            analyticsManager.log(event: .receiveNetworkScreenOpen)
        }
    }

    func network(icon: UIImage, title: String, onTap: @escaping () -> Void) -> some View {
        Button {
            onTap()
        } label: {
            HStack {
                Image(uiImage: icon)
                    .clipShape(Circle())
                    .frame(width: 48, height: 48)
                Text(title)
                    .fontWeight(.semibold)
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.night.color))
                Spacer()
                Image(.cellArrow)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(Asset.Colors.snow.color))
            .cornerRadius(16)
        }
    }
}

struct SupportedTokenNetworksView_Previews: PreviewProvider {
    static var previews: some View {
        SupportedTokenNetworksView(
            item: SupportedTokenItem(
                icon: .image(.usdt),
                name: "Tether USD",
                symbol: "USDT",
                availableNetwork: [.ethereum, .solana]
            )
        ) { _ in }
    }
}

extension SupportedTokenItemNetwork {
    func analyticsName() -> String {
        switch self {
        case .ethereum:
            return "Ethereum"
        case .solana:
            return "Solana"
        }
    }
}
