import Combine
import Foundation
import SafariServices

extension UIViewController {
    @discardableResult
    func showAlert(
        title: String?,
        message: String?,
        buttonTitles: [String]? = nil,
        highlightedButtonIndex: Int? = nil,
        destroingIndex: Int? = nil,
        completion: ((Int) -> Void)? = nil
    ) -> UIAlertController {
        view.layer.removeAllAnimations()

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        var allButtons = buttonTitles ?? [String]()
        if allButtons.isEmpty {
            allButtons.append(L10n.ok)
        }

        allButtons.enumerated().forEach { index, buttonTitle in
            let style: UIAlertAction.Style = index == destroingIndex ? .destructive : .default
            let action = UIAlertAction(title: buttonTitle, style: style, handler: { _ in
                completion?(index)
            })
            alertController.addAction(action)
            // Check which button to highlight
            if index == highlightedButtonIndex {
                alertController.preferredAction = action
            }
        }
        present(alertController, animated: true, completion: nil)
        return alertController
    }

    @discardableResult
    func showAlert(title: String?, message: String?, actions: [UIAlertAction] = []) -> UIAlertController {
        view.layer.removeAllAnimations()

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if actions.isEmpty {
            alertController.view.tintColor = UIColor.black
            alertController.addAction(UIAlertAction(title: L10n.ok, style: .default))
        }

        for action in actions {
            alertController.addAction(action)
        }

        present(alertController, animated: true, completion: nil)
        return alertController
    }

    // MARK: - Keyboard

    @objc func hideKeyboard() {
        view.endEditing(true)
    }

    func forceResizeModal() {
        view.layoutIfNeeded()
        preferredContentSize.height += 1
    }
}

// MARK: - ViewDidDisappearSwizzle

private var onCloseKey: UInt8 = 0
extension UIViewController {
    var onClose: (() -> Void)? {
        get {
            objc_getAssociatedObject(
                self,
                &onCloseKey
            ) as? () -> Void
        }
        set {
            objc_setAssociatedObject(
                self,
                &onCloseKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    @objc dynamic func viewDidDisappearOverride(_ animated: Bool) {
        viewDidDisappearOverride(animated) // Incase we need to override this method
        if isMovingFromParent || isBeingDismissed {
            onClose?()
        }
    }

    static func swizzleViewDidDisappear() {
        if self != UIViewController.self { return }
        let originalSelector = #selector(UIViewController.viewDidDisappear(_:))
        let swizzledSelector = #selector(UIViewController.viewDidDisappearOverride(_:))
        guard
            let originalMethod = class_getInstanceMethod(self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
