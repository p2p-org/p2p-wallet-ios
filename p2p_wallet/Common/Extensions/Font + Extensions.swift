//
//  Font + Extensions.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import SwiftUI
import UIKit

extension SwiftUI.Font {
    init(uiFont: UIFont) {
        self = SwiftUI.Font(uiFont as CTFont)
    }
}
