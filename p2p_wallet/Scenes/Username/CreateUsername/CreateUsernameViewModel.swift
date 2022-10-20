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
    @Injected private var createNameService: CreateNameService

    // MARK: - Properties

    let close = PassthroughSubject<Void, Never>()
    let createUsername = PassthroughSubject<Void, Never>()
    let clearUsername = PassthroughSubject<Void, Never>()

    @Published var username: String = ""
    @Published var domain: String = .nameServiceDomain
    @Published var isTextFieldFocused: Bool = false
    @Published var statusText = L10n.from6Till15Characters👌
    @Published var actionText = L10n.createName
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
                self.statusText = L10n.from6Till15Characters👌
                self.actionText = L10n.createName
            case .available:
                self.statusText = L10n.nameIsAvailable👌
                self.actionText = L10n.createName
            case .unavailable:
                self.actionText = L10n.theNameIsNotAvailable
                self.statusText = L10n.😓NameIsNotAvailable
            case .processing:
                self.actionText = L10n.waitNameCheckingIsGoing
                self.statusText = ""
            }
        }.store(in: &subscriptions)
    }

    func bindUsername() {
        clearUsername.sink { [unowned self] in
            self.username.removeAll()
        }.store(in: &subscriptions)

        createUsername.sink { [weak self] in
            guard let self = self else { return }
            self.isLoading = true
            self.createNameService.create(username: self.username)
            self.close.send(())
        }.store(in: &subscriptions)

        $username
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] currentUsername in
                guard let self = self else { return }
                guard !currentUsername.isEmpty else {
                    self.status = .initial
                    return
                }
                self.status = .processing

                guard self.isValid(username: currentUsername) else {
                    self.status = .unavailable
                    return
                }

                Task {
                    do {
                        let result = try await self.nameService.isNameAvailable(currentUsername)
                        self.status = result ? .available : .unavailable
                    } catch {
                        self.showUndefinedError()
                    }
                }
            }.store(in: &subscriptions)
    }

    func isValid(username: String) -> Bool {
        let regex = "[0-9a-z-]{6,15}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: username)
    }

    func showUndefinedError() {
        status = .initial
        notificationService.showDefaultErrorNotification()
    }
}
