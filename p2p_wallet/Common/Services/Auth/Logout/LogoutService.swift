import BankTransfer
import Resolver

protocol LogoutService {
    func logout() async
}

final class LogoutServiceImpl: LogoutService {
    func logout() async {
        await Resolver.resolve((any BankTransferService).self).clearCache()
        try? await Resolver.resolve(UserWalletManager.self).remove()
    }
}
