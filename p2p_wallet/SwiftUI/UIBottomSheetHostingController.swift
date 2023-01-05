//
//  UIBottomSheetHostingController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/01/2023.
//

import Foundation
import SwiftUI

/// UIHostingController that support dynamical height
class UIBottomSheetHostingController<Content: View>: UIHostingController<Content>, CustomPresentableViewController {
    // MARK: - Properties

    /// transactionManager required by CustomPresentableViewController
    var transitionManager: UIViewControllerTransitioningDelegate?
    
    /// (Optional) Custom modifier for height in case of custom modification needed
    var heightModifier: ((CGFloat) -> CGFloat)?
    
    // MARK: - CustomPresentableViewController

    /// fitting size for presented view, required by CustomPresentableViewController
    func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
        let expectedHeight = view.fittingHeight(targetWidth: targetWidth)
        return heightModifier?(expectedHeight) ?? expectedHeight
    }
}
