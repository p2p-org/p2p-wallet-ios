import UIKit

protocol SnackBarManagerDelegate {
    func snackBarDidDismiss()
}

public class SnackBarManager: SnackBarManagerDelegate {
    
    /// Behavior on showing snackbar
    public enum Behavior: Equatable {
        case queued
        case dismissOldWhenAddingNew
    }
    
    static public let shared = SnackBarManager()
    
    public var behavior: Behavior = .dismissOldWhenAddingNew
    
    private var queue = SynchronizedArray<SnackBar>()
    
    private var isPresenting = false
    
    private init() {}
    
    // MARK: - SnackBarManagerDelegate
    
    func snackBarDidDismiss() {
        isPresenting = false
    }
    
    func present(_ vc: SnackBar) {
        queue.append(vc)
        present()
    }
    
    func present() {
        guard let snackBar = self.queue.first() else { return }
        
        if isPresenting && behavior == .dismissOldWhenAddingNew {
            // dismiss old snackbar silently
            dismiss(snackBar, animated: false)
            return
        }
        
        guard !isPresenting else { return }
        isPresenting = true
        
        let originalTransform = snackBar.transform
        let translateTransform = originalTransform.translatedBy(x: 0.0, y: -100)
        snackBar.transform = translateTransform
        UIView.animate(withDuration: 0.2, animations: {
            snackBar.transform = originalTransform
        })

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeHandler))
        swipeGesture.direction = .up
        snackBar.addGestureRecognizer(swipeGesture)

        if snackBar.autoHide {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak snackBar] in
                guard let snackBar = snackBar else { return }
                self.dismiss(snackBar)
            }
        }
    }
    
    func dismiss(_ snackBar: SnackBar, animated: Bool = true) {
        let completion = {[weak self, weak snackBar] in
            guard let self = self, let snackBar = snackBar else {return}
            snackBar.removeFromSuperview()
            snackBar.hideCompletion?()
            self.isPresenting = false
            self.queue.remove(element: snackBar)
            self.present()
        }
        
        if animated {
            let originalTransform = snackBar.transform
            let translateTransform = originalTransform.translatedBy(x: 0, y: -250)
            UIView.animate(withDuration: 0.2) {
                snackBar.transform = translateTransform
            } completion: { _ in
                completion()
            }

        } else {
            completion()
        }
    }
    
    func dismissCurrent() {
        guard isPresenting, let first = self.queue.first() else { return }
        dismiss(first)
    }
    
    public func dismissAll() {
        while let vc = queue.removeFirst() {
            vc.removeFromSuperview()
            vc.hideCompletion?()
        }
        self.isPresenting = false
    }

    @objc private func swipeHandler(_ gestureRecognizer : UISwipeGestureRecognizer) {
        guard
            let view = gestureRecognizer.view as? SnackBar,
            gestureRecognizer.state == .ended else { return }
        self.dismiss(view)
    }
}
