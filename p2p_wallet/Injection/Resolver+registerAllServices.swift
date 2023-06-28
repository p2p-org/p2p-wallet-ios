import Resolver

extension Resolver: ResolverRegistering {
    @MainActor public static func registerAllServices() {
        // For lifetime app's services
        registerForApplicationScope()

        registerForGraphScope()

        // For services that lives inside user's session
        registerForSessionScope()

        registerForSharedScope()
    }
}

extension ResolverScope {
    static let session = ResolverScopeCache()
}
