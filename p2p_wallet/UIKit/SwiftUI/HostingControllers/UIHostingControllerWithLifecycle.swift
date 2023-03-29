import Combine
import SwiftUI

class UIHostingControllerWithLifecycle<Content: View>: UIHostingController<Content> {

    private let viewWillAppearSubject = PassthroughSubject<Void, Never>()
    private let viewDidAppearSubject = PassthroughSubject<Void, Never>()
    private let viewWillDisappearSubject = PassthroughSubject<Void, Never>()
    var viewWillAppear: AnyPublisher<Void, Never> { viewWillAppearSubject.eraseToAnyPublisher() }
    var viewDidAppear: AnyPublisher<Void, Never> { viewDidAppearSubject.eraseToAnyPublisher() }
    var viewWillDisappear: AnyPublisher<Void, Never> { viewWillDisappearSubject.eraseToAnyPublisher() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.send()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.send()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearSubject.send()
    }
}
