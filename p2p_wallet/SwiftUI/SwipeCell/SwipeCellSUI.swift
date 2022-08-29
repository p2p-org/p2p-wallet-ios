//
//  SwipeCellSUI.swift
//  p2p_wallet
//
//  Created by Ivan on 20.08.2022.
//

import Foundation
import SwiftUI

public struct SwipeCellModifier: ViewModifier {
    var id: String
    var cellWidth: CGFloat = UIScreen.main.bounds.width
    var leadingSideGroup: [SwipeCellActionItem] = []
    var trailingSideGroup: [SwipeCellActionItem] = []
    @Binding var currentUserInteractionCellID: String?
    var settings: SwipeCellSettings = .init()

    @State private var offsetX: CGFloat = 0

    let generator = UINotificationFeedbackGenerator()
    @State private var hapticFeedbackOccurred: Bool = false
    @State private var openSideLock: SwipeGroupSide?

    public func body(content: Content) -> some View {
        ZStack {
            if self.leadingSideGroup.isEmpty == false && self.offsetX != 0 {
                self.swipeToRevealArea(swipeItemGroup: self.leadingSideGroup, side: .leading)
            }

            if self.trailingSideGroup.isEmpty == false && self.offsetX != 0 {
                self.swipeToRevealArea(swipeItemGroup: self.trailingSideGroup, side: .trailing)
            }

            content
                .offset(x: self.offsetX)
                .gesture(DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onChanged(self.dragOnChanged(value:)).onEnded(dragOnEnded(value:)))

        }.frame(width: cellWidth)
            .edgesIgnoringSafeArea(.horizontal)
            .clipped()
            .onChange(of: currentUserInteractionCellID) { _ in
                if let currentDragCellID = self.currentUserInteractionCellID, currentDragCellID != self.id,
                   self.openSideLock != nil
                {
                    // if this cell has an open side area and is not the cell being dragged, close the cell
                    self.setOffsetX(value: 0)
                    // reset the drag cell id to nil
                    self.currentUserInteractionCellID = nil
                }
            }
    }

    internal func swipeToRevealArea(swipeItemGroup: [SwipeCellActionItem], side: SwipeGroupSide) -> some View {
        HStack {
            if side == .trailing {
                Spacer()
            }
            ZStack {
//                    swipeItem.backgroundColor.frame(width: self.revealAreaWidth(side: side))
                HStack(spacing: 0) {
                    ForEach(swipeItemGroup) { item in

                        Button {
                            self.setOffsetX(value: 0)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                item.actionCallback()
                            }
                        } label: {
                            self.buttonContentView(item: item, group: swipeItemGroup, side: side)
                        }.buttonStyle(BorderlessButtonStyle())
                    }
                }
            }.opacity(self.swipeRevealAreaOpacity(side: side))

            if side == .leading {
                Spacer()
            }
        }
    }

    internal func buttonContentView(item: SwipeCellActionItem, group: [SwipeCellActionItem],
                                    side: SwipeGroupSide) -> some View
    {
        ZStack {
            item.backgroundColor

            HStack {
                if self.warnSwipeOutCondition(side: side, hasSwipeOut: item.swipeOutAction) && item
                    .swipeOutButtonView != nil
                {
                    item.swipeOutButtonView!()
                } else {
                    item.buttonView()
                }
            }

        }.frame(width: itemButtonWidth(item: item, itemGroup: group, side: side))
    }

    internal func menuWidth(side: SwipeGroupSide) -> CGFloat {
        switch side {
        case .leading:
            return leadingSideGroup.map(\.buttonWidth).reduce(0, +)
        case .trailing:
            return trailingSideGroup.map(\.buttonWidth).reduce(0, +)
        }
    }

    // MARK: drag gesture

    internal func dragOnChanged(value: DragGesture.Value) {
        let horizontalTranslation = value.translation.width
        if nonDraggableCondition(horizontalTranslation: horizontalTranslation) {
            return
        }

        if openSideLock != nil {
            // if one side is open, we need to add the menu width!
            let menuWidth = openSideLock == .leading ? self.menuWidth(side: .leading) : self
                .menuWidth(side: .trailing)
            offsetX = menuWidth * openSideLock!.sideFactor + horizontalTranslation
            triggerHapticFeedbackIfNeeded(horizontalTranslation: horizontalTranslation)
            return
        }

        triggerHapticFeedbackIfNeeded(horizontalTranslation: horizontalTranslation)

        if horizontalTranslation > 8 || horizontalTranslation <
            -8
        { // makes sure the swipe cell doesn't open too easily
            currentUserInteractionCellID = id
            offsetX = horizontalTranslation
        } else {
            offsetX = 0
        }
    }

    internal func nonDraggableCondition(horizontalTranslation: CGFloat) -> Bool {
        offsetX == 0 &&
            (leadingSideGroup.isEmpty && horizontalTranslation > 0 || trailingSideGroup
                .isEmpty && horizontalTranslation < 0)
    }

    internal func dragOnEnded(value _: DragGesture.Value) {
        let swipeOutTriggerValue = cellWidth * settings.swipeOutTriggerRatio

        if offsetX == 0 {
            openSideLock = nil
        } else if offsetX > 0 {
            if leadingSideGroup.isEmpty == false {
                if offsetX < settings
                    .openTriggerValue || (openSideLock == .leading && offsetX < menuWidth(side: .leading) * 0.8)
                {
                    setOffsetX(value: 0)
                } else if let leftItem = leadingSideGroup.filter({ $0.swipeOutAction == true }).first,
                          self.offsetX.magnitude > swipeOutTriggerValue
                {
                    swipeOutAction(item: leftItem, sideFactor: 1)
                } else {
                    lockSideMenu(side: .leading)
                }

            } else {
                // leading group emtpy
                setOffsetX(value: 0)
            }
        } else if offsetX < 0 {
            if trailingSideGroup.isEmpty == false {
                if offsetX.magnitude < settings
                    .openTriggerValue || (openSideLock == .trailing && offsetX > -menuWidth(side: .trailing) * 0.8)
                {
                    setOffsetX(value: 0)
                } else if let rightItem = trailingSideGroup.filter({ $0.swipeOutAction == true }).first,
                          self.offsetX.magnitude > swipeOutTriggerValue
                {
                    swipeOutAction(item: rightItem, sideFactor: -1)
                } else {
                    lockSideMenu(side: .trailing)
                }

            } else {
                // trailing group emtpy
                setOffsetX(value: 0)
            }
        }
    }

    internal func triggerHapticFeedbackIfNeeded(horizontalTranslation: CGFloat) {
        let side: SwipeGroupSide = horizontalTranslation > 0 ? .leading : .trailing
        let group = side == .leading ? leadingSideGroup : trailingSideGroup
        //  let triggerValue  = self.cellWidth * self.settings.swipeOutTriggerRatio
        let swipeOutActionCondition = warnSwipeOutCondition(side: side, hasSwipeOut: true)
        if let item = swipeOutItemWithHapticFeedback(group: group), self.hapticFeedbackOccurred == false,
           swipeOutActionCondition == true
        {
            generator.notificationOccurred(item.swipeOutHapticFeedbackType!)
            hapticFeedbackOccurred = true
        }
    }

    internal func swipeOutItemWithHapticFeedback(group: [SwipeCellActionItem]) -> SwipeCellActionItem? {
        if let item = group.filter({ $0.swipeOutAction == true }).first {
            if item.swipeOutHapticFeedbackType != nil {
                return item
            }
        }
        return nil
    }

    internal func swipeOutAction(item: SwipeCellActionItem, sideFactor: CGFloat) {
        if item.swipeOutIsDestructive {
            let swipeOutWidth = cellWidth + 10
            setOffsetX(value: swipeOutWidth * sideFactor)
            openSideLock = nil
        } else {
            setOffsetX(value: 0) // open side lock set in function!
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            item.actionCallback()
        }
    }

    internal func lockSideMenu(side: SwipeGroupSide) {
        setOffsetX(value: side.sideFactor * menuWidth(side: side))
        openSideLock = side
        hapticFeedbackOccurred = false
    }

    internal func setOffsetX(value: CGFloat) {
        withAnimation(.spring()) {
            self.offsetX = value
        }
        if offsetX == 0 {
            openSideLock = nil
            hapticFeedbackOccurred = false
        }
    }

    internal func itemButtonWidth(item: SwipeCellActionItem, itemGroup: [SwipeCellActionItem],
                                  side: SwipeGroupSide) -> CGFloat
    {
        //  let defaultWidth = (self.offsetX.magnitude + addWidthMargin) / CGFloat(itemGroup.count)
        let dynamicButtonWidth = self.dynamicButtonWidth(item: item, itemCount: itemGroup.count, side: side)
        let triggerValue = cellWidth * settings.swipeOutTriggerRatio
        let swipeOutActionCondition = side == .leading ? offsetX > triggerValue : offsetX < -triggerValue

        if item.swipeOutAction, swipeOutActionCondition {
            return offsetX.magnitude + settings.addWidthMargin
        } else if swipeOutActionCondition, item.swipeOutAction == false,
                  itemGroup.contains(where: { $0.swipeOutAction == true })
        {
            return 0
        } else {
            return dynamicButtonWidth
        }
    }

    internal func dynamicButtonWidth(item: SwipeCellActionItem, itemCount _: Int, side: SwipeGroupSide) -> CGFloat {
        let menuWidth = self.menuWidth(side: side)
        return (offsetX.magnitude + settings.addWidthMargin) * (item.buttonWidth / menuWidth)
    }

    internal func warnSwipeOutCondition(side: SwipeGroupSide, hasSwipeOut: Bool) -> Bool {
        if hasSwipeOut == false {
            return false
        }
        let triggerValue = cellWidth * settings.swipeOutTriggerRatio
        return (side == .trailing && offsetX < -triggerValue) || (side == .leading && offsetX > triggerValue)
    }

    internal func swipeRevealAreaOpacity(side: SwipeGroupSide) -> Double {
        switch side {
        case .leading:

            return offsetX > 5 ? 1 : 0
        case .trailing:
            return offsetX < -5 ? 1 : 0
        }
    }
}

public extension View {
    /// swipe cell modifier
    /// - Parameters:
    ///   - id: the string id of this cell. The default value is a uuid string. If you want to set the currentUserInteractionCellID yourself, e.g. for tap to close functionality, you need to override this id value with your own cell id.
    ///   - cellWidth: the width of the content view - typically a cell or row in a list under which the swipe to reveal menu should appear.
    ///   - leadingSideGroup: the button group on the leading side that shall appear when the user swipes the cell to the right
    ///   - trailingSideGroup: the button group on the trailing side that shall appear when the user swipes the cell to the left
    ///   - currentUserInteractionCellID: a Binding of an optional UUID that should be set either in the view model of the parent view in which the cells appear or as a State variable into the parent view itself. Don't assign it a value!
    ///   - settings: settings. can be omitted in which case the settings struct default values apply.
    /// - Returns: the modified view of the view that can be swiped.
    func swipeCell(
        id: String = UUID().uuidString,
        cellWidth: CGFloat = UIScreen.main.bounds.width,
        leadingSideGroup: [SwipeCellActionItem] = [],
        trailingSideGroup: [SwipeCellActionItem] = [],
        currentUserInteractionCellID: Binding<String?>,
        settings: SwipeCellSettings = SwipeCellSettings()
    ) -> some View {
        modifier(SwipeCellModifier(
            id: id,
            cellWidth: cellWidth,
            leadingSideGroup: leadingSideGroup,
            trailingSideGroup: trailingSideGroup,
            currentUserInteractionCellID: currentUserInteractionCellID,
            settings: settings
        ))
    }
}

public extension View {
    func castToAnyView() -> AnyView {
        AnyView(self)
    }
}
