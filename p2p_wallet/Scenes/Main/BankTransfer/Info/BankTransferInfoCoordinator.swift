import BankTransfer
import Combine
import CountriesAPI
import Foundation
import Resolver
import SafariServices

enum BankTransferInfoCoordinatorResult {
    case canceled
    case completed
}

final class BankTransferInfoCoordinator: Coordinator<BankTransferInfoCoordinatorResult> {

    // MARK: -

    private var viewController: UIViewController!

    // MARK: -

    @Injected private var bankTransferService: any BankTransferService

    init(
        viewController: UIViewController? = nil
    ) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<BankTransferInfoCoordinatorResult, Never> {
        let viewModel = BankTransferInfoViewModel()
        let controller = UIBottomSheetHostingController(
            rootView: BankTransferInfoView(viewModel: viewModel),
            ignoresKeyboard: true
        )

        viewModel.objectWillChange
            .delay(for: 0.01, scheduler: RunLoop.main)
            .sink { [weak controller] _ in
                DispatchQueue.main.async {
                    controller?.updatePresentationLayout(animated: true)
                }
            }
            .store(in: &subscriptions)

        viewModel.showCountries.flatMap { val in
            self.coordinate(to: ChooseItemCoordinator<Country>(
                title: L10n.selectYourCountry,
                controller: controller,
                service: ChooseCountryService(),
                chosen: val,
                showDoneButton: true
            ))
        }.sink { result in
            switch result {
            case .item(let item):
                viewModel.setCountry(item as! Country)
            case .cancel: break
            }
        }.store(in: &subscriptions)

        viewModel.openProviderInfo.flatMap { [weak controller] url in
            let safari = SFSafariViewController(url: url)
            controller?.show(safari, sender: nil)
            return safari.deallocatedPublisher()
        }.sink {}.store(in: &subscriptions)

        controller.view.layer.cornerRadius = 20
        viewController.present(controller, interactiveDismissalType: .standard)

        return Publishers.Merge(
            controller.deallocatedPublisher()
                .map { BankTransferInfoCoordinatorResult.canceled },
            viewModel.openRegistration
                .handleEvents(receiveOutput: { _ in
                    controller.dismiss(animated: true)
                })
                .flatMap({ country in
                    self.coordinate(
                        to: StrigaRegistrationFirstStepCoordinator(
                            country: country,
                            navigationController: self.viewController as! UINavigationController
                        )
                    )
                })
                .map { result in
                    switch result {
                    case .completed:
                        return BankTransferInfoCoordinatorResult.completed
                    case .canceled:
                        return BankTransferInfoCoordinatorResult.canceled
                    }
                }
        )
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
