import Combine
import CountriesAPI
import Foundation
import Resolver
import SwiftUI

final class BankTransferInfoCoordinator: Coordinator<BankTransferInfoCoordinator.Result> {

    // MARK: -

    private var viewController: UINavigationController

    init(viewController: UINavigationController) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<BankTransferInfoCoordinator.Result, Never> {
        let viewModel = BankTransferInfoViewModel()
        let controller = UIHostingController(
            rootView: BankTransferInfoView(viewModel: viewModel)
        )

        viewModel.showCountries.flatMap { [unowned self, unowned controller] val in
            self.coordinate(to: ChooseItemCoordinator<Region>(
                title: L10n.selectYourCountry,
                controller: controller,
                service: ChooseCountryService(),
                chosen: val,
                showDoneButton: true
            ))
        }.sink { [weak viewModel] result in
            switch result {
            case .item(let item):
                viewModel?.setRegion(item as! Region)
            case .cancel: break
            }
        }.store(in: &subscriptions)

        controller.hidesBottomBarWhenPushed = true
        viewController.pushViewController(controller, animated: true)

        return Publishers.Merge(
            controller.deallocatedPublisher().map { BankTransferInfoCoordinator.Result.cancelled },
            viewModel.countrySubmitted.map { country in
                if let country {
                    return BankTransferInfoCoordinator.Result.selected(country)
                }
                return BankTransferInfoCoordinator.Result.cancelled
            }
        )
            .prefix(1)
            .eraseToAnyPublisher()
    }
}

extension BankTransferInfoCoordinator {
    enum Result {
        case cancelled
        case selected(Region)
    }

}
