import Foundation
import KeyAppBusiness
import Resolver

protocol ReferralProgramService {
    var link: URL { get }
}

final class ReferralProgramServiceImpl: ReferralProgramService {
    var link: URL {
        let referral = nameStorage.getName() ?? solanaAccountsService.state.value.nativeWallet?
            .address ?? ""
        return URL(string: "https://r.key.app/\(referral)")!
    }

    @Injected private var nameStorage: NameStorageType
    @Injected private var solanaAccountsService: SolanaAccountsService
}
