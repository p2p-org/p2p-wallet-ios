import AnalyticsManager
import Combine
import CoreImage.CIFilterBuiltins
import Foundation
import Resolver
import Wormhole

enum ReceiveNetwork {
    enum Image {
        case url(URL)
        case image(UIImage)
    }

    case solana(tokenSymbol: String, tokenImage: Image?)
    case ethereum(tokenSymbol: String, tokenImage: Image?)
}

class ReceiveViewModel: BaseViewModel, ObservableObject {
    // MARK: -

    let network: ReceiveNetwork
    let address: String
    private var notificationTimer: Timer?

    @Published var items: [any ReceiveRendableItem] = []
    @Published var qrImage: UIImage
    @Published var qrCenterImage: UIImage?
    @Published var qrCenterImageURL: URL?

    // MARK: -

    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var notificationsService: NotificationService
    @Injected private var analyticsManager: AnalyticsManager

    init(
        network: ReceiveNetwork,
        userWalletManager: UserWalletManager = Resolver.resolve(),
        nameStorage: NameStorageType = Resolver.resolve(),
        wormholeAPI: WormholeAPI = Resolver.resolve()
    ) {
        /// Assign network type
        self.network = network

        /// Extract user wallet from manager.
        guard let userWallet = userWalletManager.wallet else {
            address = ""
            qrImage = UIImage()
            super.init()

            return
        }

        switch network {
        case let .solana(_, icon):
            address = userWallet.account.publicKey.base58EncodedString
            qrImage = ReceiveViewModel.generateQRCode(from: address) ?? UIImage()

            // Set token icon
            switch icon {
            case let .image(image):
                qrCenterImage = image
            case let .url(url):
                qrCenterImageURL = url
            case .none:
                break
            }

            // Build list items
            func solanaNetwork(address: String, username: String?) -> [any ReceiveRendableItem] {
                var items: [any ReceiveRendableItem] = [
                    ListReceiveItem(
                        id: FieldId.solana.rawValue,
                        title: L10n.mySolanaAddress,
                        description: address,
                        showTopCorners: true,
                        showBottomCorners: username == nil,
                        isShort: false
                    ),
                ]

                if let username = username {
                    items += [
                        ListDividerReceiveItem(),
                        ListReceiveItem(
                            id: FieldId.username.rawValue,
                            title: L10n.myUsername,
                            description: username,
                            showTopCorners: false,
                            showBottomCorners: true,
                            isShort: false
                        ),
                    ]
                }

                return items
            }
            items = solanaNetwork(address: address, username: nameStorage.getName())

        case let .ethereum(tokenSymbol, icon):
            address = userWallet.ethereumKeypair.address
            qrImage = ReceiveViewModel.generateQRCode(from: address) ?? UIImage()

            // Set token icon
            switch icon {
            case let .image(image):
                qrCenterImage = image
            case let .url(url):
                qrCenterImageURL = url
            case .none:
                break
            }

            items = [
                ListReceiveItem(
                    id: FieldId.eth.rawValue,
                    title: L10n.myEthereumAddress,
                    description: address,
                    showTopCorners: true,
                    showBottomCorners: true,
                    isShort: true
                ),
                SpacerReceiveItem(),
                InstructionsReceiveCellItem(
                    instructions: [
                        ("1", L10n.sendToYourEthereumAddress(tokenSymbol)),
                        ("2", L10n.weBridgeItToSolanaWithWormhole),
                    ],
                    tip: L10n.youOnlyNeedToSignATransactionWithKeyApp
                ),
            ]
        }

        super.init()

        switch network {
        case .ethereum:
            Task {
                let value = try await wormholeAPI.getEthereumFreeFeeLimit()
                await MainActor.run {
                    items.insert(SpacerReceiveItem(), at: 1)
                    items.insert(
                        RefundBannerReceiveItem(text: L10n.weRefundBridgingCostsForAnyTransactionsOver("$\(value)")),
                        at: 2
                    )
                }
            }
        default:
            break
        }
    }

    // MARK: -

    func itemTapped(_ item: any Rendable) {
        if let row = item as? ListReceiveItem {
            clipboardManager.copyToClipboard(row.description)
            var message = ""
            switch FieldId(rawValue: row.id) {
            case .username:
                message = L10n.yourUsernameWasCopied
                analyticsManager.log(event: .receiveCopyAddressUsername)
            case .solana:
                message = L10n.yourSolanaAddressWasCopied
                analyticsManager.log(event: .receiveCopyLongAddressClick(network: network.analyticsName()))
            case .eth:
                message = L10n.yourEthereumAddressWasCopied
                analyticsManager.log(event: .receiveCopyLongAddressClick(network: network.analyticsName()))
            case .none:
                message = ""
            }
            sendNotification(text: message)
        }
    }

    func buttonTapped() {
        let message: String
        switch network {
        case .solana:
            message = L10n.yourSolanaAddressWasCopied
        case .ethereum:
            message = L10n.yourEthereumAddressWasCopied
        }
        clipboardManager.copyToClipboard(address)
        sendNotification(text: message)
        analyticsManager.log(event: .receiveCopyAddressClickButton(network: network.analyticsName()))
    }

    // MARK: - Notification

    private var shouldShowNotification = true
    private func sendNotification(text: String) {
        notificationTimer?.invalidate()
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { [weak self] _ in
            self?.shouldShowNotification = true
        })
        if shouldShowNotification {
            notificationsService.showToast(title: "✅", text: text, haptic: true)
            shouldShowNotification = false
        }
    }

    // MARK: -

    private static func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage, let transparent = outputImage.transparent?.inverted {
            if let cgimg = context.createCGImage(transparent, from: transparent.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return nil
    }
}

extension ReceiveViewModel {
    enum FieldId: String {
        case eth
        case solana
        case username
    }
}

// Analytics manager extension
extension ReceiveNetwork {
    func analyticsName() -> String {
        switch self {
        case .ethereum:
            return "Ethereum"
        case .solana:
            return "Solana"
        }
    }
}
