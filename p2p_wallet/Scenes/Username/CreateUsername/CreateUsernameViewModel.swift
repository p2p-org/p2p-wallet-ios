// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.
import Combine
import Resolver

final class CreateUsernameViewModel: BaseViewModel {
    enum Status {
        case initial
        case processing
        case available
        case unavailable
    }

    let requireSkip = PassthroughSubject<Void, Never>()
    let createUsername = PassthroughSubject<Void, Never>()

    @Published var username: String = ""
    @Published var isTextFieldFocused: Bool = false
    @Published var statusText = L10n.from3Till15LowercaseLatinSumbols👌
    @Published var status: Status = .initial

    override init() {
        super.init()

        $status.sink { [unowned self] currentStatus in
            switch currentStatus {
            case .initial:
                self.statusText = L10n.from3Till15LowercaseLatinSumbols👌
            case .available:
                self.statusText = L10n.nameIsAvailable👌
            case .unavailable:
                self.statusText = L10n.😓NameIsNotAvailable
            case .processing:
                self.statusText = ""
            }
        }.store(in: &subscriptions)

        createUsername.sink { [unowned self] in
            switch self.status {
            case .initial:
                self.status = .processing
            case .processing:
                self.status = .unavailable
            case .unavailable:
                self.status = .available
            case .available:
                self.status = .initial
            }
        }.store(in: &subscriptions)
    }
}
