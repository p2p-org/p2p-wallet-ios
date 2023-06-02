import Foundation
import BankTransfer
import Resolver
import Combine
import IdensicMobileSDK

enum KYCCoordinatorResult {
    case pass
    case canceled
}

final class KYCCoordinator: Coordinator<KYCCoordinatorResult> {
    
    // MARK: - Dependencies
    
    @Injected private var bankTransferService: any BankTransferService
    
    // MARK: - Properties
    
    private var presentingViewController: UIViewController
    private let subject = PassthroughSubject<KYCCoordinatorResult, Never>()
    
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
            } catch {
                // TODO: - Catch error
            }
            presentingViewController.hideHud()
        }
        
        return subject.prefix(1).eraseToAnyPublisher()
    }

    // MARK: - Helpers

    private func startSDK() async throws {
        // get token
        let accessToken = try await bankTransferService.getKYCToken()
        
        // initialize sdk
        let sdk = SNSMobileSDK(
            accessToken: accessToken
        )
        
        guard sdk.isReady else {
            print("Initialization failed: " + sdk.verboseStatus)
            return
        }
        
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
        
        await MainActor.run { [weak sdk, weak presentingViewController] in
            guard let presentingViewController else { return }
            sdk?.present(from: presentingViewController)
        }
    }
    
    @MainActor
    private func didFailToReceiveToken(error: Error?) {
        print(error)
        // TODO: - Handle expired token
    }
}