//
//  SwipeCellSUI_Model.swift
//  p2p_wallet
//
//  Created by Ivan on 20.08.2022.
//

import Foundation
import SwiftUI

enum SwipeGroupSide {
    case leading, trailing

    var sideFactor: CGFloat {
        switch self {
        case .leading:
            return 1

        case .trailing:
            return -1
        }
    }
}

struct SwipeCellActionItem: Identifiable {
    var id: String
    var buttonView: () -> AnyView
    var swipeOutButtonView: (() -> AnyView)?
    var buttonWidth: CGFloat
    var backgroundColor: Color
    var swipeOutAction: Bool
    var swipeOutHapticFeedbackType: UINotificationFeedbackGenerator.FeedbackType?
    var swipeOutIsDestructive: Bool
    // var swipeOutButtonViewScaleFactor: CGFloat
    var actionCallback: () -> Void

    /**
     Initializer
      - Parameter id: Required to identify each buttin in the side menu. Default is a random uuid string.
      - Parameter buttonView: The view in the foreground of the menu button. Make sure to set a maximum frame height less than the cell height!
      - Parameter swipeOutButtonView: Alternative button view that is displayed only when the offset during swipe is beyond the swipe out trigger value.
      - Parameter  buttonWidth: Width of the button. The the open side menu width is calculated from the sum of all button widths. Default is 75.
      - Parameter backgroundColor: The background colour of the the menu button.
      - Parameter swipeOutAction: A Boolean that determines if a swipe out action is activated or not. Default is false.
     - Parameter swipeOutHapticFeedbackType: If a swipeOutAction is activated, a haptic feedback will occur after the swipe out threshold is passed. Default is nil.
     - Parameter swipeOutIsDestructive: A Boolean that determines if the swipe out is destructive. If true, the content cell view will be "move out of sight" once the swipe out is triggered.
     */
    init(
        id: String = UUID().uuidString,
        buttonView: @escaping () -> AnyView,
        swipeOutButtonView: (() -> AnyView)? = nil,
        buttonWidth: CGFloat = 75,
        backgroundColor: Color,
        swipeOutAction: Bool = false,
        swipeOutHapticFeedbackType: UINotificationFeedbackGenerator.FeedbackType? = nil,
        swipeOutIsDestructive: Bool = true,
        actionCallback: @escaping () -> Void
    ) {
        self.id = id
        self.buttonView = buttonView
        self.swipeOutButtonView = swipeOutButtonView
        self.buttonWidth = buttonWidth
        self.backgroundColor = backgroundColor
        self.swipeOutAction = swipeOutAction
        self.swipeOutHapticFeedbackType = swipeOutHapticFeedbackType
        self.swipeOutIsDestructive = swipeOutIsDestructive
        self.actionCallback = actionCallback
    }
}

/// Swipe Cell Settings
struct SwipeCellSettings {
    /// initializer
    init(openTriggerValue: CGFloat = 60, swipeOutTriggerRatio: CGFloat = 0.7, addWidthMargin: CGFloat = 5) {
        self.openTriggerValue = openTriggerValue
        self.swipeOutTriggerRatio = swipeOutTriggerRatio
        self.addWidthMargin = addWidthMargin
    }

    /// minimum horizontal translation value necessary to open the side menu
    var openTriggerValue: CGFloat
    /// the ratio of the total cell width that triggers a swipe out action (provided one action has swipe out activated)
    var swipeOutTriggerRatio: CGFloat = 0.7
    /// An additional value to add to the open menu width. This is useful if the cell has rounded corners.
    var addWidthMargin: CGFloat = 5
}
