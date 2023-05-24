import Combine
import Foundation
import Resolver
import AnalyticsManager
import BankTransfer

final class BankTransferCoordinator: Coordinator<Void> {
    private var navigationController: UINavigationController!
    private var userData: BankTransfer.UserData

    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var bankTransferService: BankTransferService

    init(
        userData: BankTransfer.UserData,
        navigationController: UINavigationController? = nil
    ) {
        self.navigationController = navigationController
        self.userData = userData
    }

    override func start() -> AnyPublisher<Void, Never> {
        if bankTransferService.isBankTransferAvailable() {

        } else {
            // change country flow
        }

        let viewModel = BankTransferInfoViewModel()
        let controller = BottomSheetController(
            showHandler: true,
            rootView: BankTransferInfoView(viewModel: viewModel)
        )
        navigationController?.present(controller, animated: true)
        return controller.deallocatedPublisher().prefix(1).eraseToAnyPublisher()
//        return Publishers.Merge(
//            controller.deallocatedPublisher().map { TopupCoordinatorResult.cancel }.eraseToAnyPublisher(),
//            viewModel.tappedItem
//                .map { TopupCoordinatorResult.action(action: $0) }
//                .handleEvents(receiveOutput: { _ in
//                    controller.dismiss(animated: true)
//                })
//                .eraseToAnyPublisher()
//        ).prefix(1).eraseToAnyPublisher()
    }

//    private static func coordinator(by userData: UserData) -> Coordinator<Void> {
        // start Bank transfer flow
//        if let userId = userData.userId {
//            // show IBAN
//        } else if let country = userData.countryCode {
//
//        } else {
//
//        }
        
//    }
}
