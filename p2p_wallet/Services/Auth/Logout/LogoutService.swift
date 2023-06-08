import Resolver
import BankTransfer

protocol LogoutService {
    func logout() async
}

final class LogoutServiceImpl: LogoutService {
    @Injected private var bankTransferService: BankTransferService
    @Injected private var userWalletManager: UserWalletManager

    func logout() async {
        await bankTransferService.clearCache()
        try? await userWalletManager.remove()
    }
}
