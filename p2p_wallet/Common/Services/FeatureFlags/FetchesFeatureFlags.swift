import Foundation

protocol FetchesFeatureFlags {
    func fetchFeatureFlags(_ completion: @escaping ([FeatureFlag]) -> Void)
}
