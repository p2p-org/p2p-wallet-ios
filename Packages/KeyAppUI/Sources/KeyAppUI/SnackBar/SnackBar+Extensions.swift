import BEPureLayout
import Foundation
import UIKit

extension SnackBar {
    @discardableResult
    public convenience init(title: String? = nil, icon: UIImage? = nil, text: String, buttonTitle: String? = nil, buttonAction: (() -> Void)? = nil) {
        let button = buttonTitle != nil ? TextButton(title: buttonTitle ?? "", style: .primary, size: .small).onPressed { _ in
            buttonAction?()
        } : nil
        self.init(title: title, icon: icon, text: text, trailing: button)
    }
    
    /// Show snackbar on top of view controller.
    ///
    /// - Parameters:
    ///   - view: a target view controller
    ///   - autoDismiss: user can dismiss the snackbar
    ///   - dismissCompletion: completion called after dismiss
    public func show(in view: UIView, autoHide: Bool = true, hideCompletion: (() -> Void)? = nil) {
        // add subview and layout
        view.addSubview(self)
        autoPinEdgesToSuperviewSafeArea(with: .init(x: 4, y: 5), excludingEdge: .bottom)
        
        // set properties
        self.autoHide = autoHide
        self.hideCompletion = hideCompletion
        
        // present using SnackBarManager
        SnackBarManager.shared.present(self)
    }

    public static func hide(animated _: Bool = true) {
        SnackBarManager.shared.dismissCurrent()
    }
}
