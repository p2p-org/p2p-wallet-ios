//
// Created by Giang Long Tran on 07.02.2022.
//

import Foundation
import RxSwift
import SolanaSwift

struct RentBTC {
    typealias Service = RentBTCServiceType
}

protocol RentBTCServiceType {
    func hasAssociatedTokenAccountBeenCreated() -> Single<Bool>
    func createAssociatedTokenAccount() -> Single<SolanaSDK.TransactionID>
}
