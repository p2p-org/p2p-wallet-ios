import Foundation
import UIKit
import BankTransfer
import Resolver
import Combine

/// Result for `BankTransferClaimCoordinator`
enum BankTransferClaimCoordinatorResult {
    /// Transaction has been successfully created
    case completed
    /// Transaction has been cancelled
    case canceled
}

/// Coordinator that controlls claim operation
final class BankTransferClaimCoordinator: Coordinator<BankTransferClaimCoordinatorResult> {

    // MARK: - Dependencies

    @Injected private var bankTransferService: AnyBankTransferService<StrigaBankTransferUserDataRepository>

    // MARK: - Properties

    private let navigationController: UINavigationController
    private let transaction: StrigaClaimTransactionType
    
    private let subject = PassthroughSubject<BankTransferClaimCoordinatorResult, Never>()
    

    // MARK: - Initialization

    init(
        navigationController: UINavigationController,
        transaction: StrigaClaimTransactionType
    ) {
        self.navigationController = navigationController
        self.transaction = transaction
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<BankTransferClaimCoordinatorResult, Never> {
        // Start OTP Coordinator
        bankTransferService.value.state
            .flatMap { [unowned self] state in
                guard let phone = state.value.mobileNumber else {
                    return Just(StrigaOTPCoordinatorResult.canceled)
                        .eraseToAnyPublisher()
                }
                
                return coordinate(
                    to: StrigaOTPCoordinator(
                        viewController: navigationController,
                        phone: phone,
                        verifyHandler: { [unowned self] otp in
                            try? await Task.sleep(seconds: 1)
//                            try await bankTransferService.claimVerify(
//                                OTP: otp,
//                                challengeId: transaction.challengeId,
//                                ip: getIPAddress()
//                            )
                        },
                        resendHandler: { [unowned self] in
                            try? await Task.sleep(seconds: 1)
//                            try await bankTransferService.claimResendSMS(
//                                challengeId: transaction.challengeId
//                            )
                        }
                    )
                )
            }
            .sink { [weak self] result in
                // assert self
                guard let self else { return }
                
                // catch result
                switch result {
                case .verified:
                    // delegate work to transaction handler
                    let transactionIndex = Resolver.resolve(TransactionHandlerType.self)
                        .sendTransaction(
                            transaction
                        )

                    // return pending transaction
                    let pendingTransaction = PendingTransaction(
                        trxIndex: transactionIndex,
                        sentAt: Date(),
                        rawTransaction: transaction,
                        status: .sending
                    )
                    
                    // open detail
                    openDetails(pendingTransaction: pendingTransaction)
                        .sink { [weak self] _ in
                            // TODO: - Fix logic
                            guard let self else { return }
                            //            self.viewModel.logTransactionProgressDone()
                            
                            navigationController.popViewController(animated: true)
                            self.subject.send(.completed)
//                            self.result.send(())
//                            if self.params.dismissAfterCompletion {
//                                self.navigationController.popViewController(animated: true)
//                                self.result.send(completion: .finished)
//                            } else {
//                                self.viewModel.reset()
//                            }
                        } receiveValue: { _ in
                            // TODO: - Receive value
                        }
                        .store(in: &subscriptions)

                case .canceled:
                    self.subject.send(.canceled)
                }
            }
            .store(in: &subscriptions)
        
        return subject.prefix(1).eraseToAnyPublisher()
    }
    
    private func openDetails(pendingTransaction: PendingTransaction) -> AnyPublisher<TransactionDetailStatus, Never> {
        let viewModel = TransactionDetailViewModel(pendingTransaction: pendingTransaction)
        
//        self.viewModel.logTransactionProgressOpened()
        return coordinate(to: TransactionDetailCoordinator(
            viewModel: viewModel,
            presentingViewController: navigationController
        ))
    }
}

// MARK: - Helpers

private func getIPAddress() -> String {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
    if getifaddrs(&ifaddr) == 0 {
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { return "" }
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // wifi = ["en0"]
                // wired = ["en2", "en3", "en4"]
                // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]
                
                let name: String = String(cString: (interface.ifa_name))
                if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3",
                    let socklen = try? socklen_t((interface.ifa_addr.pointee.sa_len))
                {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    
                    getnameinfo(interface.ifa_addr, socklen, &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
    }
    return address ?? ""
}
