// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.
import Combine
import NameService
import Resolver
import UIKit
import AnalyticsManager

final class CreateUsernameViewModel: BaseViewModel, ObservableObject {
    // MARK: - Dependencies

    @Injected private var nameService: NameService
    @Injected private var notificationService: NotificationService
    @Injected private var createNameService: CreateNameService
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var analyticsService: AnalyticsService

    // MARK: - Properties

    let skip = PassthroughSubject<Void, Never>()
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

    let usernameValidation = NSPredicate(format: "SELF MATCHES %@", Constants.availableSymbols)
    let parameters: CreateUsernameParameters

    init(parameters: CreateUsernameParameters) {
        self.parameters = parameters
        super.init()

        bind()
        analyticsService.logEvent(.usernameCreationScreen)
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
            self.analyticsService.logEvent(.usernameCreationButton(result: true))
            self.close.send(())
        }.store(in: &subscriptions)

        $username
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] currentUsername in
                guard let self = self else { return }
                guard currentUsername.count >= Constants.minChars else {
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

        skip
            .sink { [weak self] _ in
                self?.log(analyticEvent: .usernameSkipButton(result: true))
            }
            .store(in: &subscriptions)
    }

    func showUndefinedError() {
        status = .initial
        notificationService.showDefaultErrorNotification()
    }

    func log(analyticEvent: AmplitudeEvent) {
        analyticsManager.log(event: analyticEvent)
    }
}

private enum Constants {
    static let availableSymbols = "^[0-9a-z-]{0,15}$"
    static let minChars = 6
}
