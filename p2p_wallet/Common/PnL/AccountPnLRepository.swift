import Foundation
import KeyAppBusiness
import PnLService
import Repository

enum PnLError: String, Error {
    case invalidUserWallet
}

class PnLProvider: Provider {
    // MARK: - Dependencies

    let service: any PnLService
    let userWalletsManager: UserWalletManager
    let solanaAccountsService: SolanaAccountsService

    // MARK: - Initializer

    init(
        service: any PnLService,
        userWalletsManager: UserWalletManager,
        solanaAccountsService: SolanaAccountsService
    ) {
        self.service = service
        self.userWalletsManager = userWalletsManager
        self.solanaAccountsService = solanaAccountsService
    }

    func fetch() async throws -> PnLModel? {
        guard let userWallet = userWalletsManager.wallet?.account.publicKey.base58EncodedString else {
            throw PnLError.invalidUserWallet
        }
        return try await service.getPNL(
            userWallet: userWallet,
            mints: solanaAccountsService.state.value.map(\.mintAddress)
        )
    }
}

class PnLRepository: Repository<PnLProvider> {
    weak var timer: Timer?

    override init(initialData: ItemType?, provider: PnLProvider) {
        super.init(initialData: initialData, provider: provider)
        timer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refresh() }
        }
        timer?.fire()
    }
}
