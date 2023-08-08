import Combine
import CountriesAPI
import Foundation
import Resolver
import SwiftUI

final class SelectRegionCoordinator: Coordinator<SelectRegionCoordinator.Result> {
    // MARK: -

    private var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<SelectRegionCoordinator.Result, Never> {
        let viewModel = SelectRegionViewModel()
        let controller = UIHostingController(
            rootView: SelectRegionView(viewModel: viewModel)
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
            case let .item(item):
                viewModel?.setRegion(item as! Region)
            case .cancel: break
            }
        }.store(in: &subscriptions)

        controller.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(controller, animated: true)

        return Publishers.Merge(
            controller.deallocatedPublisher().map { SelectRegionCoordinator.Result.cancelled },
            viewModel.countrySubmitted.map { country in
                if let country {
                    return SelectRegionCoordinator.Result.selected(country)
                }
                return SelectRegionCoordinator.Result.cancelled
            }
        )
        .prefix(1)
        .eraseToAnyPublisher()
    }
}

extension SelectRegionCoordinator {
    enum Result {
        case cancelled
        case selected(Region)
    }
}
