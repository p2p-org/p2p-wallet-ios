//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.08.2023.
//

import Foundation
import KeyAppStateMachine

class NSendInputDispatcher: Dispatcher {
    typealias State = NSendInputState

    typealias Action = NSendInputAction

    let sendProvider: SendProvider

    public init(sendProvider: SendProvider) {
        self.sendProvider = sendProvider
    }

    func shouldBeginDispatching(
        currentAction _: NSendInputAction,
        newAction _: NSendInputAction,
        currentState _: NSendInputState
    ) -> Bool {
        true
    }

    func shouldCancelCurrentAction(
        currentAction _: NSendInputAction,
        newAction _: NSendInputAction,
        currentState _: NSendInputState
    ) -> Bool {
        true
    }

    func actionWillBeginDispatching(
        action _: NSendInputAction,
        currentState: NSendInputState
    ) async -> NSendInputState? {
        currentState
    }

    func dispatch(action: NSendInputAction, currentState: NSendInputState) async -> NSendInputState {
        switch currentState {
        case .initialising:

            switch action {
            case let .calculate(input):
                return NSendInputState.calculating(input: input)
            default:
                return currentState
            }

        case let .calculating(input):

            switch action {
            case .calculating:
                return await NSendInputBusinessLogic.calculate(provider: sendProvider, input: input)
            default:
                return currentState
            }

        case .ready:

            switch action {
            case let .calculate(input):
                return NSendInputState.calculating(input: input)
            default:
                return currentState
            }

        case .error:

            switch action {
            case let .calculate(input):
                return NSendInputState.calculating(input: input)
            default:
                return currentState
            }
        }
    }

    func actionDidEndDispatching(
        action _: NSendInputAction,
        currentState: NSendInputState
    ) async -> NSendInputState? {
        Task { [weak self] in
            await self?.dispatch(action: .calculating, currentState: currentState)
        }

        return nil
    }
}
