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
    private var status: SNSMobileSDK.Status?
    
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
                await hideHud()
                await MainActor.run {
                    coordinate(to: StrigaVerificationPendingSheetCoordinator(presentingViewController: presentingViewController))
                    .map { _ in return KYCCoordinatorResult.canceled }
                    .sink { [weak self] in self?.subject.send($0) }
                    .store(in: &subscriptions)
                }
            } catch {
                // TODO: handle BankTransferError.kycRejectedCantRetry and BankTransferError.kycAttemptLimitExceeded when more info is provided
                notificationService.showDefaultErrorNotification()
                await cancel()
                await logAlertMessage(error: error, source: "striga api")
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
        if let error {
            Task {
                await logAlertMessage(error: error, source: "striga api")
            }
        }
        sdk.dismiss()
    }

    private func bindStatusChange() {
        sdk.onStatusDidChange { [weak self] (sdk, prevStatus) in
            // assign status
            self?.status = sdk.status
            
            // handle status
            switch sdk.status {
            case .initial, .incomplete, .temporarilyDeclined, .approved, .actionCompleted, .ready:
                break
            case .failed:
                let failReason = "\(sdk.failReason)"
                Task { [weak self] in
                    await self?.logAlertMessage(
                        error: SumsubSDKCustomError(message: failReason),
                        source: "KYC SDK"
                    )
                }
            case .finallyRejected:
                Task { [weak self] in
                    await self?.logAlertMessage(
                        error: SumsubSDKCustomError(message: "Applicant has been finally rejected"),
                        source: "KYC SDK"
                    )
                }
            case .pending:
                sdk.dismiss()
            }
        }
    }
    
    private func logAlertMessage(error: Error, source: String) async {
        let loggerData = await AlertLoggerDataBuilder.buildLoggerData(error: error)
        
        DefaultLogManager.shared.log(
            event: "Striga Registration iOS Alarm",
            logLevel: .alert,
            data: StrigaRegistrationAlertLoggerMessage(
                userPubkey: loggerData.userPubkey,
                platform: loggerData.platform,
                appVersion: loggerData.appVersion,
                timestamp: loggerData.timestamp,
                error: .init(
                    source: source,
                    kycSDKState: String(reflecting: status ?? .initial)
                        .replacingOccurrences(of: "SNSMobileSDK.Status.", with: ""),
                    error: loggerData.otherError ?? ""
                )
            )
        )
    }
}

private struct SumsubSDKCustomError: Error, Encodable {
    let message: String?
}
