import Combine
import UIKit

/// Publisher to read keyboard appearance changes.
protocol KeyboardVisibilityReadable {
    var isKeyboardShown: AnyPublisher<Bool, Never> { get }
}

extension KeyboardVisibilityReadable {
    var isKeyboardShown: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}
