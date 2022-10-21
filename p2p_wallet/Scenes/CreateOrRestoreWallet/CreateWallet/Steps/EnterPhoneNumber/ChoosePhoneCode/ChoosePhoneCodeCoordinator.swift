import Combine
import CountriesAPI
import Foundation

final class ChoosePhoneCodeCoordinator: Coordinator<Country?> {
    // MARK: - Properties

    let presentingViewController: UIViewController
    let selectedDialCode: String?
    let selectedCountryCode: String?

    // MARK: - Initializer

    init(
        selectedDialCode: String? = nil,
        selectedCountryCode: String? = nil,
        presentingViewController: UIViewController
    ) {
        self.presentingViewController = presentingViewController
        self.selectedDialCode = selectedDialCode
        self.selectedCountryCode = selectedCountryCode
    }

    override func start() -> AnyPublisher<Country?, Never> {
        let vm = ChoosePhoneCodeViewModel(
            selectedDialCode: selectedDialCode,
            selectedCountryCode: selectedCountryCode
        )
        let vc = ChoosePhoneCodeViewController(viewModel: vm)
        vc.isModalInPresentation = true
        let nc = UINavigationController(rootViewController: vc)
        nc.navigationBar.isTranslucent = false
        nc.view.backgroundColor = vc.view.backgroundColor
        presentingViewController.present(nc, animated: true)

        return vm.didClose.withLatestFrom(vm.$data)
            .map { $0.first(where: { $0.isSelected })?.value }
            .eraseToAnyPublisher()
    }
}
