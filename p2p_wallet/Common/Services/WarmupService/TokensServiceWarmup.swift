import Foundation
import KeyAppBusiness
import Resolver
import TokenService

class TokenServiceWarmupProcess: WarmupProcess {
    func start() async {
        let tokenService: SolanaTokensService = Resolver.resolve()

        await(tokenService as? KeyAppSolanaTokenRepository)?.setup()
    }
}
