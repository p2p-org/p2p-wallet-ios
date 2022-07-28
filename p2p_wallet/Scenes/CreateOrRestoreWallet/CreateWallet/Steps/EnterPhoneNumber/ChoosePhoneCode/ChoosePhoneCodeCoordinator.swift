//
//  ChoosePhoneCodeCoordinator.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/07/2022.
//

import Combine
import CountriesAPI
import Foundation

final class ChoosePhoneCodeCoordinator: Coordinator<Country?> {
    // MARK: - Properties

    let presentingViewController: UIViewController
    let selectedCountry: Country?

    // MARK: - Initializer

    init(selectedCountry: Country? = nil, presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        self.selectedCountry = selectedCountry
    }

    override func start() -> AnyPublisher<Country?, Never> {
        let vm = ChoosePhoneCodeViewModel(selectedCountry: selectedCountry)
        let vc = ChoosePhoneCodeViewController(viewModel: vm)
        vc.isModalInPresentation = true
        let nc = UINavigationController(rootViewController: vc)
        nc.navigationBar.isTranslucent = false
        nc.view.backgroundColor = vc.view.backgroundColor
        presentingViewController.present(nc, animated: true)

        return vm.input.didClose.withLatestFrom(vm.$data)
            .map { $0.first(where: { $0.isSelected })?.value }
            .eraseToAnyPublisher()
    }
}
