//
//  GT3Error+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/04/2022.
//

import Foundation
import GT3Captcha

extension GT3Error: LocalizedError {
    public var errorDescription: String? {
        if error_code == "error_12" {
            return L10n.theNameServiceIsExperiencingSomeIssuesPleaseTryAgainLater
        }
        return nil
    }

    var shouldBlockUI: Bool {
        if error_code == "error_12" {
            return true
        }
        return false
    }
}
