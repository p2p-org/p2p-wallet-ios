import Foundation

class ScreenAnalyticTracker {
    static let shared = ScreenAnalyticTracker()

    private(set) var currentViewId = ""

    private init() {}

    func setCurrentViewId(_ viewId: String) {
        currentViewId = viewId
    }
}
