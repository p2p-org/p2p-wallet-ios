import Foundation
import Resolver
import KeyAppBusiness

class TokenServiceWarmupProcess: WarmupProcess {
    func start() async {
        let tokenService: SolanaTokensService = Resolver.resolve()
        
        await (tokenService as? KeyAppSolanaTokenRepository)?.setup()
    }
}
