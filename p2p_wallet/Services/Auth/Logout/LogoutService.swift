import Resolver
import BankTransfer

protocol LogoutService {
    func logout() async
}

final class LogoutServiceImpl: LogoutService {
    func logout() async {
        await Resolver.resolve(BankTransferService.self).clearCache()
        try? await Resolver.resolve(UserWalletManager.self).remove()
    }
}
