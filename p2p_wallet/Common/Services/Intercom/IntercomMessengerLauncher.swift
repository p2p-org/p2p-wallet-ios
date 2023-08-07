import Intercom
import Resolver

final class IntercomMessengerLauncher: HelpCenterLauncher {
    private let attributesService = IntercomUserAttributesService()

    func launch() {
        attributesService.setParameters()

        Intercom.presentMessenger()
    }
}
