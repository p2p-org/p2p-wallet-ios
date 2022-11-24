//
//  NetworkViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 31.08.2022.
//

import AnalyticsManager
import Combine
import Foundation
import RenVMSwift
import Resolver
import SolanaSwift

final class NetworkViewModel: ObservableObject {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var renVMService: LockAndMintService
    @Injected private var changeNetworkResponder: ChangeNetworkResponder

    private let dismissSubject = PassthroughSubject<Void, Never>()
    var dismiss: AnyPublisher<Void, Never> { dismissSubject.eraseToAnyPublisher() }

    let endPoints: [APIEndPoint]

    init() {
        endPoints = APIEndPoint.definedEndpoints
            .sorted {
                if $0 == Defaults.apiEndPoint {
                    return true
                } else if $1 != Defaults.apiEndPoint {
                    return false
                }
                return false
            }
    }

    func cancel() {
        dismissSubject.send()
    }

    func setEndPoint(_ endPoint: APIEndPoint) {
        guard Defaults.apiEndPoint != endPoint else { return }

        analyticsManager.log(event: AmplitudeEvent.networkChanging(networkName: endPoint.address))
        Task {
            try await renVMService.expireCurrentSession()
            await MainActor.run {
                changeNetworkResponder.changeAPIEndpoint(to: endPoint)
            }
        }
    }
}
