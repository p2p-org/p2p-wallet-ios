import Foundation
import Resolver

class MigrationWarmupProcess: WarmupProcess {
    func start() async {
        let migration1Key = "APIEndpoint.migrationKey2"
        if !UserDefaults.standard.bool(forKey: migration1Key) {
            // Migrate to endpoint solana.keyapp.org
            Resolver.resolve(ChangeNetworkResponder.self)
                .changeAPIEndpoint(
                    to: .init(
                        address: "https://solana.keyapp.org",
                        network: .mainnetBeta,
                        additionalQuery: .secretConfig("KEYAPP_ORG_API_KEY")
                    )
                )

            // Reset input type to token
            Defaults.isTokenInputTypeChosen = true

            // Set at migrated
            UserDefaults.standard.set(true, forKey: migration1Key)
        }
    }
}
