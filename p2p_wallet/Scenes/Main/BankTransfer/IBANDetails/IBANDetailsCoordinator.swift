import BankTransfer
import Combine
import SwiftUI

final class IBANDetailsCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let eurAccount: EURUserAccount

    @SwiftyUserDefault(keyPath: \.strigaIBANInfoDoNotShow, options: .cached)
    private var strigaIBANInfoDoNotShow: Bool

    init(navigationController: UINavigationController, eurAccount: EURUserAccount) {
        self.navigationController = navigationController
        self.eurAccount = eurAccount
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = IBANDetailsViewModel(eurAccount: eurAccount)
        let view = IBANDetailsView(viewModel: viewModel)

        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.hidesBottomBarWhenPushed = true
        vc.title = L10n.euroAccount

        navigationController.pushViewController(vc, animated: true) { [weak self] in
            guard let self, self.strigaIBANInfoDoNotShow == false else { return }
            self.openInfo()
        }

        viewModel.warningTapped
            .sink { [weak self] in self?.openInfo() }
            .store(in: &subscriptions)

        return vc.deallocatedPublisher()
            .prefix(1)
            .eraseToAnyPublisher()
    }

    private func openInfo() {
        coordinate(to: IBANDetailsInfoCoordinator(navigationController: navigationController))
            .sink { _ in }
            .store(in: &subscriptions)
    }
}

extension UserData {
    var isIBANNotReady: Bool {
        kycStatus == .approved && wallet?.accounts.eur?.enriched == false
    }
}
