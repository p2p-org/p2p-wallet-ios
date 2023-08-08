//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.08.2023.
//

import Foundation
import KeyAppStateMachine

public final class SendInputDispatcher: Dispatcher {
    public typealias State = NSendInputState

    public typealias Action = NSendInputAction

    let sendProvider: SendProvider

    public init(sendProvider: SendProvider) {
        self.sendProvider = sendProvider
    }

    public func shouldBeginDispatching(
        currentAction _: NSendInputAction,
        newAction _: NSendInputAction,
        currentState _: NSendInputState
    ) -> Bool {
        true
    }

    public func shouldCancelCurrentAction(
        currentAction _: NSendInputAction,
        newAction _: NSendInputAction,
        currentState _: NSendInputState
    ) -> Bool {
        true
    }

    public func actionWillBeginDispatching(
        action _: NSendInputAction,
        currentState: NSendInputState
    ) async -> NSendInputState? {
        currentState
    }

    public func onEnter(currentState: NSendInputState) {
        Task { [weak self] in
            await self?.dispatch(action: .calculating, currentState: currentState)
        }
    }

    public func dispatch(action: NSendInputAction, currentState: NSendInputState) async -> NSendInputState {
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

    public func actionDidEndDispatching(
        action _: NSendInputAction,
        currentState _: NSendInputState
    ) async -> NSendInputState? {
        nil
    }
}
