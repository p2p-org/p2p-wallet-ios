//
// Created by Giang Long Tran on 14.12.21.
//

import Foundation
import SafariServices

class WebViewController {
    static func inReaderMode(url: String) -> UIViewController? {
        guard let url = URL(string: url) else { return nil }
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        return SFSafariViewController(url: url, configuration: config)
    }
}
