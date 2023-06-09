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
                
                await MainActor.run {
                    presentingViewController.hideHud()
                }
            } catch {
                
                await MainActor.run {
                    presentingViewController.hideHud()
                }
                
                // TODO: - Catch error

                subject.send(.canceled)
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

    private func didFailToReceiveToken(error: Error?) {
        print(error)
        sdk.dismiss()
    }
}
