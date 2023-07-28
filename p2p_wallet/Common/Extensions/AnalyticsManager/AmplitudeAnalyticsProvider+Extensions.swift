import Amplitude
import Foundation

extension AmplitudeAnalyticsProvider {
    func setUserId(_ id: String?) {
        guard let id else { return }
        Amplitude.instance().setUserId(id)
    }
}
