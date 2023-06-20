import Foundation
import BankTransfer
import Resolver
import Combine
import IdensicMobileSDK

enum KYCCoordinatorResult {
    case pass
    case canceled
}

enum KYCCoordinatorError: Error {
    case sdkInitializationFailed
}

final class KYCCoordinator: Coordinator<KYCCoordinatorResult> {
    
    // MARK: - Dependencies
    
    @Injected private var bankTransferService: any BankTransferService
    @Injected private var notificationService: NotificationService

    // MARK: - Properties
    
    private var presentingViewController: UIViewController
    private let subject = PassthroughSubject<KYCCoordinatorResult, Never>()
    private var sdk: SNSMobileSDK!
    
    // MARK: - Initializer

    init(
        presentingViewController: UINavigationController
    ) {
        self.presentingViewController = presentingViewController
    }
    
    // MARK: - Methods

    override func start() -> AnyPublisher<KYCCoordinatorResult, Never> {
        // showloading
        presentingViewController.showIndetermineHud()
        
        // start sdk
        Task {
            do {
                try await startSDK()
                await hideHud()
            } catch let error as NSError where error.isNetworkConnectionError {
                notificationService.showConnectionErrorNotification()
                await cancel()
            } catch BankTransferError.kycVerificationInProgress {
                await MainActor.run {
                    showPendingAlert()
                }
                await cancel()
            } catch {
                // TODO: handle BankTransferError.kycRejectedCantRetry and BankTransferError.kycAttemptLimitExceeded when more info is provided
                notificationService.showDefaultErrorNotification()
                await cancel()
            }
        }
        
        return subject.prefix(1).eraseToAnyPublisher()
    }

    // MARK: - Helpers

    private func startSDK() async throws {
        // get token
        let accessToken = try await bankTransferService.getKYCToken()
        
        // initialize sdk
        sdk = SNSMobileSDK(
            accessToken: accessToken
        )
        
        // check if it is ready
        guard sdk.isReady else {
            print("Initialization failed: " + sdk.verboseStatus)
            throw KYCCoordinatorError.sdkInitializationFailed
        }
        
        // handle token expiration
        sdk.setTokenExpirationHandler { onComplete in
            print("Sumsub Token has expired -- renewing...")
            Task { [weak self] in
                do {
                    guard let newToken = try await self?.bankTransferService.getKYCToken()
                    else {
                        self?.didFailToReceiveToken(error: nil)
                        return
                    }
                    
                    await MainActor.run {
                        onComplete(newToken)
                    }
                } catch {
                    self?.didFailToReceiveToken(error: error)
                }
            }
        }

        bindStatusChange()

        // present sdk
        presentKYC()
    }

    private func presentKYC() {
        // present
        sdk.present(from: presentingViewController)
        
        // handle dismissal
        sdk.dismissHandler { [weak subject] (sdk, mainVC) in
            mainVC.dismiss(animated: true, completion: nil)
            subject?.send(.canceled)
        }
    }

    private func showPendingAlert() {
        let alert = UIAlertController(
            title: L10n.yourDocumentsVerificationIsPending,
            message: L10n.usuallyItTakesAFewHours,
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(
            title: L10n.ok,
            style: .default,
            handler: nil
        )

        alert.addAction(okAction)

        presentingViewController.present(alert, animated: true)
    }

    private func cancel() async {
        await hideHud()
        subject.send(.canceled)
    }

    private func hideHud() async {
        await MainActor.run {
            presentingViewController.hideHud()
        }
    }

    private func didFailToReceiveToken(error: Error?) {
        print(error)
        sdk.dismiss()
    }

    private func bindStatusChange() {
        sdk.onStatusDidChange { (sdk, prevStatus) in
            switch sdk.status {
            case .initial, .incomplete, .temporarilyDeclined, .finallyRejected, .approved, .actionCompleted, .failed, .ready:
                break
            case .pending:
                sdk.dismiss()
            }
        }
    }
}
