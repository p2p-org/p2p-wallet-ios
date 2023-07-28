import Foundation
import UIKit
import BankTransfer
import Resolver
import Combine
import SwiftyUserDefaults
import Onboarding

/// Result for `BankTransferClaimCoordinator`
enum BankTransferClaimCoordinatorResult {
    /// Transaction has been successfully created
    case completed(PendingTransaction)
    /// Transaction has been cancelled
    case canceled
}

/// Coordinator that controlls claim operation
final class BankTransferClaimCoordinator: Coordinator<BankTransferClaimCoordinatorResult> {

    // MARK: - Dependencies

    @Injected private var bankTransferService: AnyBankTransferService<StrigaBankTransferUserDataRepository>

    // MARK: - Properties

    private let navigationController: UINavigationController
    private let transaction: any StrigaConfirmableTransactionType

    private let subject = PassthroughSubject<BankTransferClaimCoordinatorResult, Never>()

    // Request otp timer properties
    @SwiftyUserDefault(keyPath: \.strigaOTPResendCounter, options: .cached)
    private var resendCounter: ResendCounter?

    // MARK: - Initialization

    init(
        navigationController: UINavigationController,
        transaction: any StrigaConfirmableTransactionType
    ) {
        self.navigationController = navigationController
        self.transaction = transaction
        super.init()
        self.increaseTimer() // We need to increase time because transaction once was called before, then resend logic will appear
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<BankTransferClaimCoordinatorResult, Never> {
        // Start OTP Coordinator
        bankTransferService.value.state
            .prefix(1)
            .receive(on: RunLoop.main)
            .flatMap { [unowned self] state in
                guard let phone = state.value.mobileNumber else {
                    return Just(StrigaOTPCoordinatorResult.canceled)
                        .eraseToAnyPublisher()
                }

                return coordinate(
                    to: StrigaOTPCoordinator(
                        navigationController: navigationController,
                        phone: phone,
                        navigation: .nextToRoot,
                        verifyHandler: { [unowned self] otp in
                            guard let userId = await bankTransferService.value.repository.getUserId() else {
                                throw BankTransferError.missingMetadata
                            }
                            try? await Task.sleep(seconds: 1)
//                            try await bankTransferService.value.repository
//                            .claimVerify(
//                                userId: userId,
//                                challengeId: transaction.challengeId,
//                                ip: getIPAddress(),
//                                verificationCode: otp
//                            )
                        },
                        resendHandler: { [unowned self] in
                            guard let userId = await bankTransferService.value.repository.getUserId() else {
                                throw BankTransferError.missingMetadata
                            }
                            try await bankTransferService.value.repository.claimResendSMS(
                                userId: userId,
                                challengeId: transaction.challengeId
                            )
                        }
                    )
                )
            }
            .handleEvents(receiveOutput: { [unowned self] result in
                switch result {
                case .verified:
                    navigationController.popToRootViewController(animated: true)
                case .canceled:
                    navigationController.popViewController(animated: true)
                }
            })
            .map { [unowned self] result -> BankTransferClaimCoordinatorResult in
                switch result {
                case .verified:
                    let transactionIndex = Resolver.resolve(TransactionHandlerType.self)
                        .sendTransaction(transaction, status: .sending)
                    // return pending transaction
                    let pendingTransaction = PendingTransaction(
                        trxIndex: transactionIndex,
                        sentAt: Date(),
                        rawTransaction: transaction,
                        status: .sending
                    )
                    return BankTransferClaimCoordinatorResult.completed(pendingTransaction)
                case .canceled:
                    return BankTransferClaimCoordinatorResult.canceled
                }
            }.eraseToAnyPublisher()
    }

    // Start OTP request timer
    private func increaseTimer() {
        if let resendCounter {
            self.resendCounter = resendCounter.incremented()
        } else {
            resendCounter = .zero()
        }
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
