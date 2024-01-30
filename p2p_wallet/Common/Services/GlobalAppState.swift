import Foundation
import NameService
import Resolver

class GlobalAppState: ObservableObject {
    static let shared = GlobalAppState()

    // App logic
    @Published var shouldPlayAnimationOnHome: Bool = false
    @Published var preferDirectSwap: Bool = true

    // Debug features
    @Published var forcedWalletAddress: String = ""
    @Published var forcedFeeRelayerEndpoint: String? = Defaults.forcedFeeRelayerEndpoint {
        didSet {
            Defaults.forcedFeeRelayerEndpoint = forcedFeeRelayerEndpoint
            ResolverScope.session.reset()
        }
    }

    // Endpoints
    @Published var nameServiceEndpoint: String {
        didSet {
            Defaults.forcedNameServiceEndpoint = nameServiceEndpoint
            ResolverScope.session.reset()
        }
    }

    @Published var pushServiceEndpoint: String = Environment.current == .release || Environment.current == .test ?
        String.secretConfig("NOTIFICATION_SERVICE_ENDPOINT_RELEASE")! :
        String.secretConfig("NOTIFICATION_SERVICE_ENDPOINT")!

    // New swap endpoint
    @Published var newSwapEndpoint: String {
        didSet {
            Defaults.forcedNewSwapEndpoint = newSwapEndpoint
            ResolverScope.session.reset()
        }
    }

    @Published var newReferralProgramEndpoint: String {
        didSet {
            Defaults.forcedReferralProgramEndpoint = newReferralProgramEndpoint
            ResolverScope.session.reset()
        }
    }

    // TODO: Refactor!
    @Published var surveyID: String?
    @Published var sendViaLinkUrl: URL?
    @Published var swapUrl: URL?

    private init() {
        if let forcedValue = Defaults.forcedNameServiceEndpoint {
            nameServiceEndpoint = forcedValue
        } else {
            nameServiceEndpoint = "https://\(String.secretConfig("NAME_SERVICE_ENDPOINT_NEW")!)"
        }

        if let forcedValue = Defaults.forcedNewSwapEndpoint {
            newSwapEndpoint = forcedValue
        } else {
            newSwapEndpoint = "https://swap-v6.key.app"
        }

        if let forcedValue = Defaults.forcedReferralProgramEndpoint {
            newReferralProgramEndpoint = forcedValue
        } else {
            newReferralProgramEndpoint = String.secretConfig("REFERRAL_PROGRAM_ENDPOINT")!
        }
    }

    @Published var bridgeEndpoint: String = (Environment.current == .release) ?
        String.secretConfig("BRIDGE_PROD")! :
        String.secretConfig("BRIDGE_DEV")!

    @Published var tokenEndpoint: String = (Environment.current == .release) ?
        String.secretConfig("TOKEN_SERVICE_PROD")! :
        String.secretConfig("TOKEN_SERVICE_DEV")!
}
