import Foundation
import Amplitude

extension AmplitudeAnalyticsProvider {
    func setIdentifier(_ identifier: AmplitudeIdentifier) {
        guard
            let value = identifier.value as? NSObject,
            let identify = AMPIdentify().set(identifier.name, value: value)
        else { return }
        Amplitude.instance().identify(identify)
    }
    
    func setUserId(_ id: String?) {
        guard let id else { return }
        Amplitude.instance().setUserId(id)
    }
}

enum AmplitudeIdentifier {
    case userHasPositiveBalance(positive: Bool)
    case userAggregateBalance(balance: Double)

    // Onboarding
    case userRestoreMethod(restoreMethod: String)
    case userDeviceshare(deviceshare: Bool)
}

extension AmplitudeIdentifier: MirrorableEnum {
    var name: String {
        mirror.label.snakeAndFirstUppercased ?? ""
    }

    var value: Any {
        mirror.params.values.first ?? ""
    }
}
