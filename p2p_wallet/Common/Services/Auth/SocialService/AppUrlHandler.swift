import UIKit

protocol AppUrlHandler {
    func handle(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool
}
