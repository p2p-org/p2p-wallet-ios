//
// Created by Giang Long Tran on 28.01.2022.
//

import UIKit

class LockScreenWrapperViewController: UIViewController {
    let childViewController: UIViewController
    let lockView = LockView()

    var isLocked: Bool = false {
        didSet {
            debugPrint(isLocked)
            lockView.isHidden = !isLocked
        }
    }

    init(_ childViewController: UIViewController) {
        self.childViewController = childViewController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(childViewController)
        view.addSubview(childViewController.view)
        childViewController.view.autoPinEdgesToSuperviewEdges()
        childViewController.didMove(toParent: self)

        view.addSubview(lockView)
        lockView.autoPinEdgesToSuperviewEdges()
        lockView.isHidden = !isLocked
    }
}
