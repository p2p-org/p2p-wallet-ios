// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding

extension SocialProvider {
    var socialType: SocialType {
        switch self {
        case .apple:
            return .apple
        case .google:
            return .google
        }
    }
}

struct ReactiveProcess<T> {
    let data: T
    let finish: (Error?) -> Void

    func start(_ compute: @escaping () async throws -> Void) {
        Task {
            do {
                try await compute()
                finish(nil)
            } catch {
                finish(error)
            }
        }
    }
}

extension Subject {
    func sendProcess<V>(data: V, _ finish: @escaping (Error?) -> Void) where Output == ReactiveProcess<V> {
        send(ReactiveProcess<V>(data: data, finish: finish))
    }

    func sendProcess(_ finish: @escaping (Error?) -> Void) where Output == ReactiveProcess<Void> {
        send(ReactiveProcess<Void>(data: (), finish: finish))
    }

    func sendProcess() where Output == ReactiveProcess<Void> {
        send(ReactiveProcess<Void>(data: (), finish: { _ in }))
    }
}

struct ResponsiveReactiveProcess<Result, Data> {
    let data: Data
    let finish: (Result?, Error?) -> Void

    func start(_ compute: @escaping () async throws -> Result) {
        Task {
            do {
                finish(try await compute(), nil)
            } catch {
                finish(nil, error)
            }
        }
    }
}

extension Subject {
    func sendResponsiveProcess<Result, Data>(data: Data, _ finish: @escaping (Result?, Error?) -> Void)
    where Output == ResponsiveReactiveProcess<Result, Data> {
        send(ResponsiveReactiveProcess<Result, Data>(data: data, finish: finish))
    }

    func sendResponsiveProcess<Result>(_ finish: @escaping (Result?, Error?) -> Void)
    where Output == ResponsiveReactiveProcess<Result, Void> {
        send(ResponsiveReactiveProcess<Result, Void>(data: (), finish: finish))
    }
}
