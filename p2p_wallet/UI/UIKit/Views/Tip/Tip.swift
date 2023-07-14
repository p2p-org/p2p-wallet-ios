import CoreGraphics
import UIKit

protocol TipManagerDelegate: AnyObject {
    func next(after number: Int)
}

final class TipManager {

    weak var delegate: TipManagerDelegate?
    private weak var currentTip: TipView?

    init() { }

    func createTip(content: TipContent, theme: TipTheme, pointerPosition: TipPointerPosition) -> UIView {
        hideCurrentTip()

        let tipView = TipView(content: content, theme: theme, pointerPosition: pointerPosition)

        tipView.nextButtonHandler = { [weak self] in
            if content.count == content.currentNumber {
                self?.hideCurrentTip()
            }
            else {
                self?.delegate?.next(after: content.currentNumber)
            }
        }

        tipView.skipButtonHandler = { [weak self] in
            self?.hideCurrentTip()
        }

        self.currentTip = tipView

        return tipView
    }

    private func hideCurrentTip() {
        currentTip?.removeFromSuperview()
    }
}
