//
//  SwapTokenSettings.FeeCellContent.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 27.12.2021.
//

import UIKit

extension SwapTokenSettings {
    struct FeeCellContent {
        let wallet: Wallet?
        let tokenLabelText: String?
        let isSelected: Bool
        let onTapHandler: () -> Void
    }
}
