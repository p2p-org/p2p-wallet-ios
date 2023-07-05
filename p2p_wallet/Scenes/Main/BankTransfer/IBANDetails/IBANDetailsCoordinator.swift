import SwiftUI
import SafariServices
import Combine
import BankTransfer

final class IBANDetailsCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let eurAccount: EURUserAccount

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

        viewModel.openLearnMode
            .sink { [weak vc] url in
                let safari = SFSafariViewController(url: url)
                vc?.present(safari, animated: true)
            }
            .store(in: &subscriptions)

        navigationController.pushViewController(vc, animated: true)

        return vc.deallocatedPublisher()
            .prefix(1)
            .eraseToAnyPublisher()
    }
}

extension UserData {
    var isIBANNotReady: Bool {
        self.kycStatus == .approved && self.wallet?.accounts.eur?.enriched == false
    }
}
