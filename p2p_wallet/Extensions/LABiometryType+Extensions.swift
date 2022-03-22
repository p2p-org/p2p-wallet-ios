//
//  LABiometryType+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/11/2020.
//

import Foundation
import LocalAuthentication

extension LABiometryType {
    var icon: UIImage? {
        switch self {
        case .touchID:
            return .touchId
        case .faceID:
            return .faceId
        default:
            return nil
        }
    }

    var stringValue: String {
        switch self {
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        default:
            return ""
        }
    }

    static var current: LABiometryType {
        // retrieve policy
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    static var isEnabled: Bool {
        Defaults.isBiometryEnabled
    }
}
