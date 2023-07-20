import UIKit
import KeyAppUI

final class TipExampleViewController: UIViewController {

    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var fourthLabel: UILabel!
    @IBOutlet weak var fifthLabel: UILabel!

    private lazy var tipManager: TipManager = {
        let tipManager = TipManager()
        tipManager.delegate = self
        return tipManager
    }()

    @IBAction func startTipExamplePressed(_ sender: UIButton) {
        next(after: .zero)
    }
}

extension TipExampleViewController: TipManagerDelegate {
    func next(after number: Int) {
        let nextTip: UIView
        switch number {
        case 0:
            nextTip = tipManager.createTip(content: createTipContent(number: 1, count: 5), theme: .night, pointerPosition: .topRight)
            view.addSubview(nextTip)
            nextTip.autoPinEdge(.top, to: .bottom, of: firstButton, withOffset: 4)
            nextTip.autoPinEdge(.leading, to: .leading, of: view, withOffset: 4)
        case 1:
            nextTip = tipManager.createTip(content: createTipContent(number: 2, count: 5), theme: .snow, pointerPosition: .rightCenter)
            view.addSubview(nextTip)
            nextTip.autoPinEdge(.trailing, to: .leading, of: secondLabel, withOffset: -4)
            nextTip.autoAlignAxis(.horizontal, toSameAxisOf: secondLabel)
        case 2:
            nextTip = tipManager.createTip(content: createTipContent(number: 3, count: 5), theme: .lime, pointerPosition: .bottomLeft)
            view.addSubview(nextTip)
            nextTip.autoPinEdge(.bottom, to: .top, of: thirdLabel, withOffset: -4)
            nextTip.autoPinEdge(.leading, to: .leading, of: thirdLabel, withOffset: -16)
        case 3:
            nextTip = tipManager.createTip(content: createTipContent(number: 4, count: 5), theme: .night, pointerPosition: .rightBottom)
            view.addSubview(nextTip)
            nextTip.autoPinEdge(.bottom, to: .bottom, of: fourthLabel, withOffset: 12)
            nextTip.autoPinEdge(.trailing, to: .leading, of: fourthLabel, withOffset: -4)
        case 4:
            nextTip = tipManager.createTip(content: createTipContent(number: 5, count: 5), theme: .lime, pointerPosition: .leftTop)
            view.addSubview(nextTip)
            nextTip.autoPinEdge(.leading, to: .trailing, of: fifthLabel, withOffset: 16)
            nextTip.autoPinEdge(.top, to: .top, of: fifthLabel, withOffset: -20)
        default:
            fatalError()
        }
        nextTip.autoSetDimension(.width, toSize: 250, relation: .lessThanOrEqual)
    }
}

private extension TipExampleViewController {
    func createTipContent(number: Int, count: Int) -> TipContent {
        return TipContent(
            currentNumber: number,
            count: count,
            text: """
            Hi there! 👋
            As needed, we will guide you through the main: \(number) functions.
            """,
            nextButtonText: "Next",
            skipButtonText: "Skip all"
        )
    }
}
