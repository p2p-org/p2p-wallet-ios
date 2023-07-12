import Foundation
import UIKit

protocol ResizablePresentationController: UIPresentationController {
    func presentedViewDidSwipe(gestureRecognizer: UIPanGestureRecognizer)
}
