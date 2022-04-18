//
//  GT3Error+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/04/2022.
//

import Foundation
import GT3Captcha

extension GT3Error: LocalizedError {
    private static var nameServiceUnavailableCodes = ["_12"]

    public var errorDescription: String? {
        if isNameServiceUnavailable {
            return L10n.theNameServiceIsExperiencingSomeIssuesPleaseTryAgainLater
        }
        return nil
    }

    var isNameServiceUnavailable: Bool {
        Self.nameServiceUnavailableCodes.contains(error_code)
    }
}
