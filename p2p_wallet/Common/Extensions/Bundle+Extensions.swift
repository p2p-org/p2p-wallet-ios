import Foundation
import Resolver
import UIKit

extension Bundle {
    // MARK: - Build number, marketing number
    
    
    
    
    
    

    var releaseVersionNumber: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildVersionNumber: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }

    var fullVersionNumber: String? {
        guard let releaseVersionNumber = releaseVersionNumber,
              let buildVersionNumber = buildVersionNumber
        else {
            return nil
        }
        return releaseVersionNumber + "(" + buildVersionNumber + ")"
    }
}
