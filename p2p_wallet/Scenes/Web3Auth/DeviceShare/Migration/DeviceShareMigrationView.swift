//
//  DeviceShareMigrationView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.06.2023.
//

import KeyAppUI
import Onboarding
import SwiftUI

struct DeviceShareMigrationView: View {
    @ObservedObject var viewModel: DeviceShareMigrationViewModel

    var body: some View {
        LoadingAnimationLayout(
            title: "Updating your authorization device",
            subtitle: "",
            isProgressVisible: true
        )
    }
}

struct DeviceShareMigrationView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceShareMigrationView(viewModel: .init(facade: TKeyMockupFacade()))
    }
}
