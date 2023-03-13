import Combine
import CoreImage.CIFilterBuiltins
import Foundation
import Resolver

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

    init(
        network: ReceiveNetwork,
        userWalletManager: UserWalletManager = Resolver.resolve()
    ) {
        /// Assign network type
        self.network = network

        /// Extract user wallet from manager.
        guard let userWallet = userWalletManager.wallet else {
            self.address = ""
            self.qrImage = UIImage()
            super.init()

            return
        }

        switch network {
        case let .solana(_, icon):
            self.address = userWallet.account.publicKey.base58EncodedString
            self.qrImage = ReceiveViewModel.generateQRCode(from: address) ?? UIImage()

            // Set token icon
            switch icon {
            case let .image(image):
                self.qrCenterImage = image
            case let .url(url):
                self.qrCenterImageURL = url
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
                        showBottomCorners: username == nil
                    )
                ]

                if let username = username {
                    items += [
                        ListDividerReceiveItem(),
                        ListReceiveItem(
                            id: FieldId.username.rawValue,
                            title: L10n.myUsername,
                            description: username.withNameServiceDomain(),
                            showTopCorners: false,
                            showBottomCorners: true
                        )
                    ]
                }

                return items
            }

            self.items = solanaNetwork(address: address, username: userWallet.name)

        case let .ethereum(tokenSymbol, icon):
            self.address = userWallet.ethereumKeypair.address
            self.qrImage = ReceiveViewModel.generateQRCode(from: address) ?? UIImage()

            // Set token icon
            switch icon {
            case let .image(image):
                self.qrCenterImage = image
            case let .url(url):
                self.qrCenterImageURL = url
            case .none:
                break
            }

            self.items = [
                ListReceiveItem(
                    id: FieldId.eth.rawValue,
                    title: L10n.myEthereumAddress,
                    description: address,
                    showTopCorners: true,
                    showBottomCorners: true
                ),
                SpacerReceiveItem(),
                RefundBannerReceiveItem(text: L10n.weRefundBridgingCostsForAnyTransactionsOver50),
                SpacerReceiveItem(),
                InstructionsReceiveCellItem(
                    instructions: [
                        ("1", L10n.sendToYourEthereumAddress(tokenSymbol)),
                        ("2", L10n.weBridgeItToSolanaWithWormhole)
                    ],
                    tip: L10n.youOnlyNeedToSignATransactionWithKeyApp
                )
            ]
        }

        super.init()
    }

    // MARK: -

    func itemTapped(_ item: any Rendable) {
        if let row = item as? ListReceiveItem {
            clipboardManager.copyToClipboard(row.description)
            var message = ""
            switch FieldId(rawValue: row.id) {
            case .username:
                message = L10n.yourUsernameWasCopied
            case .solana:
                message = L10n.yourSolanaAddressWasCopied
            case .eth:
                message = L10n.yourEthereumAddressWasCopied
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
    }

    // MARK: - Notification

    private var shouldShowNotification = true
    private func sendNotification(text: String) {
        notificationTimer?.invalidate()
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { [weak self] (timer) in
            self?.shouldShowNotification = true
        })
        if shouldShowNotification {
            notificationsService.showInAppNotification(.init(emoji: "✅", message: text))
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