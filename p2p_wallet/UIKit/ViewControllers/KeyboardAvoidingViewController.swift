import BEPureLayout
import Combine
import SwiftUI
import UIKit

/// A view controller that embeds a SwiftUI view and controls Keyboard
final class KeyboardAvoidingViewController<Content: View>: UIViewController {
    enum NavigationBarVisibility {
        case `default`
        case hidden
        case visible
    }
    
    private let rootView: Content
    private let hostingController: UIHostingController<Content>
    private let navigationBarVisibility: NavigationBarVisibility
    
    private var originalIsNavigationBarHidden: Bool?

    init(rootView: Content, navigationBarVisibility: NavigationBarVisibility = .default) {
        self.rootView = rootView
        self.navigationBarVisibility = navigationBarVisibility
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
        getAllTextFields(fromView: view).first?.becomeFirstResponder()
        
        originalIsNavigationBarHidden = navigationController?.isNavigationBarHidden
        switch navigationBarVisibility {
        case .default:
            break
        case .visible:
            navigationController?.setNavigationBarHidden(false, animated: false)
        case .hidden:
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideKeyboard()
        
        switch navigationBarVisibility {
        case .default:
            break
        default:
            if let originalIsNavigationBarHidden {
                navigationController?.setNavigationBarHidden(originalIsNavigationBarHidden, animated: false)
            }
        }
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
