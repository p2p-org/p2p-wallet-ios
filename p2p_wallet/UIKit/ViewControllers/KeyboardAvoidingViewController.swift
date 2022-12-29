import BEPureLayout
import Combine
import SwiftUI
import UIKit

/// A view controller that embeds a SwiftUI view and controls Keyboard
final class KeyboardAvoidingViewController<Content: View>: UIViewController {
    private let rootView: Content
    private let hostingController: UIHostingController<Content>

    init(rootView: Content, ignoresKeyboard: Bool = false) {
        self.rootView = rootView
        hostingController = UIHostingController(rootView: rootView, ignoresKeyboard: ignoresKeyboard)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    @objc dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()

        NotificationCenter.default
          .addObserver(self, selector: #selector(activityHandler(_:)),
                       name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default
          .addObserver(self, selector: #selector(activityHandler(_:)),
                       name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        openKeyboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideKeyboard()
    }

    private func openKeyboard() {
        getAllTextFields(fromView: view).first?.becomeFirstResponder()
    }

    private func setupLayout() {
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        hostingController.view.autoPinEdgesToSuperviewEdges()
    }

    private func getAllTextFields(fromView view: UIView) -> [UITextField] {
        view.subviews.flatMap { view -> [UITextField] in
            if view is UITextField {
                return [view as! UITextField]
            } else {
                return getAllTextFields(fromView: view)
            }
        }
    }

    @objc private func activityHandler(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didBecomeActiveNotification:
            openKeyboard()
        case UIApplication.didEnterBackgroundNotification:
            hideKeyboard()
        default:
            break
        }
    }
}
