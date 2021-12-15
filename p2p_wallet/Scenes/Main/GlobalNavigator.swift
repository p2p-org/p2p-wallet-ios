//
//  GlobalNavigator.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 15.12.2021.
//

import UIKit
import Resolver

protocol NavigationControllerStorageType: AnyObject {
    var navigationController: UINavigationController? { get set }
}

final class GlobalNavigationControllerStorage: NavigationControllerStorageType {
    weak var navigationController: UINavigationController?
}

protocol GlobalNavigatorType: AnyObject {
    func push(viewController: UIViewController)
}

final class GlobalNavigator: GlobalNavigatorType {
    private let storage: NavigationControllerStorageType

    init(storage: NavigationControllerStorageType) {
        self.storage = storage
    }

    func push(viewController: UIViewController) {
        storage.navigationController?.pushViewController(viewController, animated: true)
    }
}
