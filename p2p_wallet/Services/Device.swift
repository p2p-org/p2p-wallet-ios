//
// Created by Giang Long Tran on 17.11.21.
//

import Foundation
import LocalAuthentication

struct Device {
    static func requiredOwner(onSuccess: (() -> Void)?, onFailure: ((Error?) -> Void)?) {
        let myContext = LAContext()
        
        myContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: L10n.confirmItSYou) { (success, error) in
            guard success else {
                onFailure?(error)
                return
            }
            DispatchQueue.main.sync {
                onSuccess?()
            }
        }
    }
}
