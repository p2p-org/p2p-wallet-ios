//
//  UIHostingControllerWithoutNavigation.swift
//  p2p_wallet
//
//  Created by Ivan on 09.08.2022.
//

import Combine
import SwiftUI

final class UIHostingControllerWithoutNavigation<Content: View>: UIHostingControllerWithLifecycle<Content> {
    var navigationIsHidden = true

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationController?.setNavigationBarHidden(navigationIsHidden, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(navigationIsHidden, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(navigationIsHidden, animated: true)
    }
}
