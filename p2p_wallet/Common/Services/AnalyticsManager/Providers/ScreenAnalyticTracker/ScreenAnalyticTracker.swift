import Foundation

public class ScreenAnalyticTracker {
    public static let shared = ScreenAnalyticTracker()

    private(set) var currentViewId = ""

    private init() {}

    public func setCurrentViewId(_ viewId: String) {
        currentViewId = viewId
    }
}
