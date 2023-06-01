import Foundation
import Combine

final class StrigaTransferCoordinator: Coordinator<Void> {

    let navigation: UINavigationController
    init(navigation: UINavigationController) {
        self.navigation = navigation
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = StrigaTransferView()
        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.hidesBottomBarWhenPushed = true
        navigation.setViewControllers([navigation.viewControllers.first, vc].compactMap { $0 }, animated: true)
        return vc.deallocatedPublisher().prefix(1).eraseToAnyPublisher()
    }
}
