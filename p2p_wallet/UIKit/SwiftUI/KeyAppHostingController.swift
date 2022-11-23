//
//  UIHostingControllerWithoutNavigation.swift
//  p2p_wallet
//
//  Created by Ivan on 09.08.2022.
//

import Combine
import SwiftUI

final class KeyAppHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
    }
}
