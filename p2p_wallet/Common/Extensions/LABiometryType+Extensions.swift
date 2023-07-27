//
//  LABiometryType+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/11/2020.
//

import Foundation
import LocalAuthentication

extension LABiometryType {
    var stringValue: String {
        switch self {
        case .touchID:
            return L10n.touchID
        case .faceID:
            return L10n.faceID
        default:
            return ""
        }
    }
}
