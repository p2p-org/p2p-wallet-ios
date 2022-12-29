import BEPureLayout
import Combine
import SwiftUI
import UIKit

struct KeyboardAvoidingOption: OptionSet {
    let rawValue: Int
    static let onAppear = KeyboardAvoidingOption(rawValue: 1 << 0)
    static let onDisappear = KeyboardAvoidingOption(rawValue: 1 << 1)
}

/// A view controller that embeds a SwiftUI view and controls Keyboard
final class KeyboardAvoidingViewController<Content: View>: UIViewController {
    private let rootView: Content
    private let hostingController: UIHostingController<Content>
    private let options: KeyboardAvoidingOption

    init(rootView: Content, options: KeyboardAvoidingOption = [.onAppear, .onDisappear]) {
        self.rootView = rootView
        self.options = options
        hostingController = UIHostingController(rootView: rootView)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    @objc dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard options.contains(.onAppear) else { return }
        openKeyboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard options.contains(.onDisappear) else { return }
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
}
