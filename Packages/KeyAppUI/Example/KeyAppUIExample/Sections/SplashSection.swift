//
//  SplashSection.swift
//  KeyAppUIExample
//
//  Created by Chung Tran on 05/07/2022.
//

import Foundation
import BEPureLayout
import KeyAppUI

class SplashSection: BECompositionView {
    
    override func build() -> UIView {
        BEVStack(spacing: 15) {
            UILabel(text: "Splash", textSize: 22).padding(.init(only: .top, inset: 20))
            TextButton(
                title: "Open Splash",
                style: .primary,
                size: .large
            )
        }
    }
}
