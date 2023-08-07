import KeyAppUI
import Onboarding
import SwiftUI

struct DeviceShareMigrationView: View {
    @ObservedObject var viewModel: DeviceShareMigrationViewModel

    var body: some View {
        LoadingAnimationLayout(
            title: L10n.updating,
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
