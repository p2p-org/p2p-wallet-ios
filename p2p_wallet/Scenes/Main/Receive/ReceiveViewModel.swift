import Combine
import Foundation
import CoreImage.CIFilterBuiltins
import Resolver

@MainActor class ReceiveViewModel: BaseViewModel, ObservableObject {
    let qrCenterImage: UIImage?
    let address: String
    private var kind: Kind = .solana

    // MARK: -

    @Published var items: [any ReceiveCellItem] = []
    @Published var qrImage: UIImage

    // MARK: -

    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var notificationsService: NotificationService

    // MARK: -

    init(address: String, username: String?, qrCenterImage: UIImage? = nil) {
        self.qrImage = ReceiveViewModel.generateQRCode(from: address) ?? UIImage()
        self.qrCenterImage = qrCenterImage
        self.address = address
        super.init()
        self.items = [
            ListRowReceiveCellItem(
                id: FieldId.solana.rawValue,
                title: L10n.mySolanaAddress,
                description: address,
                showTopCorners: true,
                showBottomCorners: (username == nil)
            )
        ]
        if let username {
            self.items.append(ListDividerReceiveCellItem())
            self.items.append(
                ListRowReceiveCellItem(
                    id: FieldId.username.rawValue,
                    title: L10n.myUsername,
                    description: username,
                    showTopCorners: false,
                    showBottomCorners: true
                )
            )
        }
    }

    init(ethAddress: String, token: String, qrCenterImage: UIImage? = nil) {
        self.qrImage = ReceiveViewModel.generateQRCode(from: ethAddress) ?? UIImage()
        self.qrCenterImage = qrCenterImage
        self.address = ethAddress
        self.kind = .eth
        super.init()

        self.items = [
            ListRowReceiveCellItem(
                id: FieldId.eth.rawValue,
                title: L10n.myEthereumAddress,
                description: ethAddress,
                showTopCorners: true,
                showBottomCorners: true
            ),
            SpacerReceiveCellItem(),
            RefundBannerReceiveCellItem(text: L10n.weRefundBridgingCostsForAnyTransactionsOver50),
            SpacerReceiveCellItem(),
            InstructionsReceiveCellItem(
                instructions: [
                    ("1", L10n.sendToYourEthereumAddress(token)),
                    ("2", L10n.weBridgeItToSolanaWithWormhole)
                ],
                tip: L10n.youOnlyNeedToSignATransactionWithKeyApp
            )
        ]
    }

    // MARK: -

    func itemTapped(_ item: any ReceiveCellItem) {
        if let row = item as? ListRowReceiveCellItem {
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
            notificationsService.showInAppNotification(.init(emoji: "✅", message: message))
        }
    }

    func buttonTapped() {
        clipboardManager.copyToClipboard(address)
        notificationsService.showInAppNotification(.init(
            emoji: "✅",
            message: kind == .eth ? L10n.yourEthereumAddressWasCopied : L10n.yourSolanaAddressWasCopied)
        )
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

    enum Kind {
        case solana
        case eth
    }
}
