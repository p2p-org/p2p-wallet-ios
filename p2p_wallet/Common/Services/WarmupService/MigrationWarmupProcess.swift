import Foundation
import Resolver

class MigrationWarmupProcess: WarmupProcess {
    func start() async {
        // Migrate to endpoint solana.keyapp.org
        let migration1Key = "APIEndpoint.migrationKey1"
        if !UserDefaults.standard.bool(forKey: migration1Key) {
            Resolver.resolve(ChangeNetworkResponder.self)
                .changeAPIEndpoint(
                    to: .init(
                        address: "https://solana.keyapp.org",
                        network: .mainnetBeta,
                        additionalQuery: .secretConfig("KEYAPP_ORG_API_KEY")
                    )
                )
            UserDefaults.standard.set(true, forKey: migration1Key)
        }
    }
}
