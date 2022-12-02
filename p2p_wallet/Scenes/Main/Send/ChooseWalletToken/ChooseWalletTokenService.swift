import SolanaSwift
import Send
import Resolver

protocol ChooseWalletTokenService {
    func getWallets() async throws -> [Wallet]
}

final class ChooseWalletTokenServiceImpl: ChooseWalletTokenService {

    private let strategy: ChooseWalletTokenStrategy

    @Injected private var walletsRepository: WalletsRepository

    private lazy var feeWalletsService: SendChooseFeeService = SendChooseFeeServiceImpl(
        wallets: walletsRepository.getWallets(),
        feeRelayer: Resolver.resolve(),
        orcaSwap: Resolver.resolve()
    )

    init(strategy: ChooseWalletTokenStrategy) {
        self.strategy = strategy
    }

    func getWallets() async throws -> [Wallet] {
        switch strategy {
        case let .feeToken(feeInSOL):
            return try await feeWalletsService.getAvailableWalletsToPayFee(feeInSOL: feeInSOL)
        case .sendToken:
            return walletsRepository.getWallets().filter { wallet in
                (wallet.lamports ?? 0) > 0 && !wallet.isNFTToken
            }
        }
    }
}
