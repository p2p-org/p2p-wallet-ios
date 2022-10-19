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
    @Injected private var storage: AccountStorageType
    @Injected private var createNameService: CreateNameService

    // MARK: - Properties

    let requireSkip = PassthroughSubject<Void, Never>()
    let createUsername = PassthroughSubject<Void, Never>()
    let clearUsername = PassthroughSubject<Void, Never>()
    let transactionCreated = PassthroughSubject<Void, Never>()

    @Published var username: String = ""
    @Published var domain: String = .nameServiceDomain
    @Published var isTextFieldFocused: Bool = false
    @Published var statusText = L10n.from6Till15Characters👌
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

        createUsername.sink { [weak self] in
            guard let self = self else { return }
            self.isLoading = true
            Task {
                do {
                    guard let account = self.storage.account else {
                        throw UndefinedNameServiceError.unknown
                    }
                    let result = try await self.nameService.create(
                        name: self.username,
                        publicKey: account.publicKey.base58EncodedString,
                        privateKey: account.secretKey
                    )
                    self.isLoading = false
                    self.createNameService.send(
                        transaction: result.transaction,
                        name: self.username,
                        owner: account.publicKey.base58EncodedString
                    )
                    self.transactionCreated.send(())
                } catch NameServiceError.invalidName {
                    self.isLoading = false
                    self.status = .initial
                } catch {
                    self.isLoading = false
                    self.showUndefinedError()
                    self.status = .initial
                }
            }
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

    func showUndefinedError() {
        status = .initial
        notificationService.showDefaultErrorNotification()
    }
}
