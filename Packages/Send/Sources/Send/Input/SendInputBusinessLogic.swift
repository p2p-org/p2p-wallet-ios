// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

struct SendInputBusinessLogic {
    static func sendInputBusinessLogic(
        state: SendInputState,
        action: SendInputAction,
        services: SendInputServices
    ) async -> SendInputState {
        switch action {
        case let .initialize(params):
            return await initialize(state: state, services: services, params: params)
        case let .changeAmountInToken(amount):
            return await sendInputChangeAmountInToken(state: state, amount: amount, services: services)
        case let .changeAmountInFiat(amount):
            return await sendInputChangeAmountInFiat(state: state, amount: amount, services: services)
        case let .changeUserToken(token):
            return await changeToken(state: state, token: token, services: services)
        case let .changeFeeToken(feeToken):
            return await changeFeeToken(state: state, feeToken: feeToken, services: services)

        default:
            return state
        }
    }

    static func checkIsReady(_ state: SendInputState) -> Bool {
        switch state.status {
        case .requiredInitialize:
            return false
        case .error(reason: .requiredInitialize):
            return false
        case .error(reason: .initializeFailed(_)):
            return false
        default:
            return true
        }
    }

    static func handleFeeCalculationError(
        state: SendInputState,
        services _: SendInputServices,
        error: Error
    ) async -> SendInputState {
        let status: SendInputState.Status
        let error = error as NSError

        if error.isNetworkConnectionError {
            status = .error(reason: .networkConnectionError(error))
        } else {
            status = .error(reason: .feeCalculationFailed)
        }
        return state.copy(status: status)
    }

    static func handleMinAmountCalculationError(
        state: SendInputState,
        error: Error
    ) async -> SendInputState {
        let status: SendInputState.Status
        let error = error as NSError

        if error.isNetworkConnectionError {
            status = .error(reason: .networkConnectionError(error))
        } else {
            status = .error(reason: .unknown(error))
        }
        return state.copy(status: status)
    }
}

private extension NSError {
    var isNetworkConnectionError: Bool {
        self.code == NSURLErrorNetworkConnectionLost || self.code == NSURLErrorNotConnectedToInternet
    }
}
