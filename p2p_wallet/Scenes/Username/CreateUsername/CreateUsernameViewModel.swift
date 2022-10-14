// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.
import Combine
import NameService
import Resolver
import UIKit

final class CreateUsernameViewModel: BaseViewModel {
    // MARK: - Dependencies

    @Injected private var nameService: NameService
    @Injected private var notificationService: NotificationService

    // MARK: - Properties

    let requireSkip = PassthroughSubject<Void, Never>()
    let createUsername = PassthroughSubject<Void, Never>()
    let clearUsername = PassthroughSubject<Void, Never>()

    @Published var username: String = ""
    @Published var domain: String = .nameServiceDomain
    @Published var isTextFieldFocused: Bool = false
    @Published var statusText = L10n.from3Till15Characters👌
    @Published var status = CreateUsernameStatus.initial
    @Published var isLoading: Bool = false
    @Published var isSkipEnabled: Bool = false
    @Published var backgroundColor: UIColor

    init(parameters: CreateUsernameParameters) {
        isSkipEnabled = parameters.isSkipEnabled
        backgroundColor = parameters.backgroundColor

        super.init()

        bind()
    }
}

private extension CreateUsernameViewModel {
    func bind() {
        bindUsername()
        bindStatus()
    }

    func bindStatus() {
        $status.sink { [unowned self] currentStatus in
            switch currentStatus {
            case .initial:
                self.statusText = L10n.from3Till15Characters👌
            case .available:
                self.statusText = L10n.nameIsAvailable👌
            case .unavailable:
                self.statusText = L10n.😓NameIsNotAvailable
            case .processing:
                self.statusText = ""
            }
        }.store(in: &subscriptions)
    }

    func bindUsername() {
        clearUsername.sink { [unowned self] in
            self.username.removeAll()
        }.store(in: &subscriptions)

        createUsername.sink { [unowned self] in
            self.isLoading = true
        }.store(in: &subscriptions)

        $username
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [unowned self] currentUsername in
                guard !currentUsername.isEmpty else {
                    self.status = .initial
                    return
                }
                self.status = .processing
                Task {
                    do {
                        let result = try await nameService.isNameAvailable(currentUsername)
                        if result {
                            self.status = .available
                        } else {
                            self.status = .unavailable
                        }
                    } catch {
                        self.showUndefinedError()
                    }
                }
            }.store(in: &subscriptions)
    }

    func showUndefinedError() {
        status = .initial
        notificationService.showDefaultErrorNotification()
    }
}
