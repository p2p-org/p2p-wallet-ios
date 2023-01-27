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

    private let viewWillAppearSubject: PassthroughSubject<Bool, Never> = .init()
    public var viewWillAppearPublisher: AnyPublisher<Bool, Never> { viewWillAppearSubject.eraseToAnyPublisher() }
    
    init(rootView: Content, ignoresKeyboard: Bool = false, navigationBarVisibility: NavigationBarVisibility = .default) {
        self.rootView = rootView
        self.navigationBarVisibility = navigationBarVisibility
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewWillAppearSubject.send(animated)
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
            if presentedViewController == nil && navigationController?.presentedViewController == nil {
                openKeyboard()
            }
        case UIApplication.didEnterBackgroundNotification:
            hideKeyboard()
        default:
            break
        }
    }
}
