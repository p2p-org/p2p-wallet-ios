import BankTransfer
import Resolver

final class BankTransferWarmup: WarmupProcess {
    @Injected private var service: BankTransferService

    func start() async {
        await service.reload()
    }
}
