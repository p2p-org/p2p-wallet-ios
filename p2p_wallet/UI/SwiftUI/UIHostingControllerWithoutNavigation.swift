import Combine
import SwiftUI

final class UICustomHostingController<Content: View>: UIHostingController<Content> {
    typealias Builder = (UICustomHostingController<Content>, _ animated: Bool) -> Void

    let viewWillAppearFn: Builder?

    init(rootView: Content, viewWillAppear: Builder?) {
        viewWillAppearFn = viewWillAppear

        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    @MainActor dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        viewWillAppearFn?(self, animated)
    }
}

final class UIHostingControllerWithoutNavigation<Content: View>: UIHostingController<Content> {
    var navigationIsHidden = true

    private let viewWillAppearSubject = PassthroughSubject<Void, Never>()
    private let viewDidAppearSubject = PassthroughSubject<Void, Never>()
    private let viewWillDisappearSubject = PassthroughSubject<Void, Never>()
    var viewWillAppear: AnyPublisher<Void, Never> { viewWillAppearSubject.eraseToAnyPublisher() }
    var viewDidAppear: AnyPublisher<Void, Never> { viewDidAppearSubject.eraseToAnyPublisher() }
    var viewWillDisappear: AnyPublisher<Void, Never> { viewWillDisappearSubject.eraseToAnyPublisher() }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationController?.setNavigationBarHidden(navigationIsHidden, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.send()
        navigationController?.setNavigationBarHidden(navigationIsHidden, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.send()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearSubject.send()
        navigationController?.setNavigationBarHidden(navigationIsHidden, animated: true)
    }
}
