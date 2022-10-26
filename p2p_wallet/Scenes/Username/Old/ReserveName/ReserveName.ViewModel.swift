//
//  ReserveName.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 26.11.2021.
//

import AnalyticsManager
import Combine
import Foundation
import GT3Captcha
import NameService
import Resolver
import UIKit

protocol ReserveNameViewModelType: AnyObject {
    var navigatableScenePublisher: AnyPublisher<ReserveName.NavigatableScene?, Never> { get }
    var textFieldStatePublisher: AnyPublisher<ReserveName.TextFieldState, Never> { get }
    var mainButtonStatePublisher: AnyPublisher<ReserveName.MainButtonState, Never> { get }
    var textFieldTextSubject: CurrentValueSubject<String?, Never> { get }
    var usernameValidationLoadingPublisher: AnyPublisher<Bool, Never> { get }
    var isLoadingPublisher: AnyPublisher<Bool, Never> { get }
    var kind: ReserveNameKind { get }

    func showTermsOfUse()
    func showPrivacyPolicy()
    func skipButtonPressed()
    func goBack()
    func goForth()
}

extension ReserveName {
    @MainActor
    class ViewModel: NSObject, ObservableObject {
        // MARK: - Dependencies

        @Injected private var notificationsService: NotificationService
        @Injected private var analyticsManager: AnalyticsManager
        private let nameService: NameService = Resolver.resolve()
        private let owner: String
        private let reserveNameHandler: ReserveNameHandler?
        private lazy var manager: GT3CaptchaManager = {
            let manager = GT3CaptchaManager(
                api1: NameServiceImpl.captchaAPI1Url,
                api2: nil,
                timeout: 10
            )
            manager.delegate = self
            return manager
        }()

        // MARK: - Properties

        let kind: ReserveNameKind
        private let goBackOnCompletion: Bool

        private var subscriptions = [AnyCancellable]()

        private var nameAvailabilityTask: Task<Void, Never>?

        // MARK: - Subject

        @Published private var navigatableScene: NavigatableScene?
        @Published private var textFieldState: TextFieldState = .empty
        @Published private var mainButtonState: ReserveName.MainButtonState = .empty
        let textFieldTextSubject = CurrentValueSubject<String?, Never>(nil)
        @Published private var usernameValidationLoading: Bool = false
        @Published private var isLoading: Bool = false

        init(
            kind: ReserveNameKind,
            owner: String,
            reserveNameHandler: ReserveNameHandler?,
            goBackOnCompletion: Bool = false,
            checkBeforeReserving: Bool
        ) {
            self.kind = kind
            self.owner = owner
            self.reserveNameHandler = reserveNameHandler
            self.goBackOnCompletion = goBackOnCompletion

            super.init()

            if checkBeforeReserving {
                checkIfUsernameHasAlreadyBeenRegistered()
            }

            bind()
            manager.registerCaptcha(nil)
        }

        deinit {
            print("\(String(describing: self)) deinited")
        }

        private func bind() {
            textFieldTextSubject
                .sink { [weak self] in
                    self?.checkUsernameForAvailability(string: $0)
                }
                .store(in: &subscriptions)
        }

        private func checkUsernameForAvailability(string: String?) {
            nameAvailabilityTask?.cancel()

            guard let string = string, !string.isEmpty else {
                return setEmptyState()
            }

            usernameValidationLoading = true

            nameAvailabilityTask = Task { [weak self] in
                guard let self = self else { return }
                let isNameAvailable = (try? await self.nameService.isNameAvailable(string)) ?? false
                let state: TextFieldState = isNameAvailable ? .available(name: string) : .unavailable(name: string)
                self.textFieldState = state
                self.mainButtonState = isNameAvailable ? .canContinue : .unavailableUsername
                self.usernameValidationLoading = false
            }
        }

        private func checkIfUsernameHasAlreadyBeenRegistered() {
            isLoading = true

            Task {
                do {
                    let name = try await nameService.getName(owner)
                    isLoading = false
                    if let name = name {
                        nameDidReserve(name)
                    }
                } catch {
                    isLoading = false
                }
            }
        }

        private func setEmptyState() {
            textFieldState = .empty
            mainButtonState = .empty
        }

        private func reserveName(
            geetest_seccode: String,
            geetest_challenge: String,
            geetest_validate: String
        ) {
            guard let name = textFieldTextSubject.value else { return }
            analyticsManager.log(event: AmplitudeEvent.usernameSaved(lastScreen: "Onboarding"))

            isLoading = true

            Task {
                do {
                    _ = try await nameService
                        .post(
                            name: name,
                            params: .init(
                                owner: owner,
                                credentials: .init(
                                    geetest_validate: geetest_validate,
                                    geetest_seccode: geetest_seccode,
                                    geetest_challenge: geetest_challenge
                                )
                            )
                        )
                    isLoading = false
                    nameDidReserve(name)
                } catch {
                    isLoading = false
                    if error is UndefinedNameServiceError {
                        notificationsService
                            .showInAppNotification(.error(L10n
                                    .theNameServiceIsExperiencingSomeIssuesPleaseTryAgainLater))
                        return
                    }
                    notificationsService.showInAppNotification(.error(error))
                }
            }
        }

        @MainActor
        private func nameDidReserve(_ name: String) {
            reserveNameHandler?.handleName(name)
            analyticsManager.log(event: AmplitudeEvent.usernameReserved)
            notificationsService.showInAppNotification(
                .message(L10n.usernameWasReserved(name))
            )

            if goBackOnCompletion {
                goBack()
            }
        }

        private func handleSkipAlertAction(isProceed: Bool) {
            if isProceed {
                skip()
            }
        }

        private func skip() {
            reserveNameHandler?.handleName(nil)
        }
    }
}

extension ReserveName.ViewModel: ReserveNameViewModelType {
    var usernameValidationLoadingPublisher: AnyPublisher<Bool, Never> {
        $usernameValidationLoading.eraseToAnyPublisher()
    }

    func skipButtonPressed() {
        navigatableScene = .skipAlert { [weak self] in
            let isFilled = self?.textFieldState == ReserveName.TextFieldState
                .empty ? "Not_Filled" : "Filled"
            self?.analyticsManager.log(event: AmplitudeEvent.usernameSkipped(usernameField: isFilled))
            self?.handleSkipAlertAction(isProceed: $0)
        }
    }

    var navigatableScenePublisher: AnyPublisher<ReserveName.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var textFieldStatePublisher: AnyPublisher<ReserveName.TextFieldState, Never> {
        $textFieldState.eraseToAnyPublisher()
    }

    var mainButtonStatePublisher: AnyPublisher<ReserveName.MainButtonState, Never> {
        $mainButtonState.eraseToAnyPublisher()
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        $isLoading.eraseToAnyPublisher()
    }

    func goForth() {
        manager.startGTCaptchaWith(animated: true)
    }

    func goBack() {
        navigatableScene = .back
    }

    func showTermsOfUse() {
        navigatableScene = .termsOfUse
    }

    func showPrivacyPolicy() {
        navigatableScene = .privacyPolicy
    }
}

extension ReserveName.ViewModel: GT3CaptchaManagerDelegate {
    func gtCaptcha(_: GT3CaptchaManager, errorHandler error: GT3Error) {
        if error.isNameServiceUnavailable {
            mainButtonState = .unavailableNameService
        }
        notificationsService
            .showInAppNotification(.message(error.readableDescription))
    }

    func gtCaptcha(
        _: GT3CaptchaManager,
        didReceiveCaptchaCode code: String,
        result: [AnyHashable: Any]?,
        message _: String?
    ) {
        guard code == "1",
              let geetest_seccode = result?["geetest_seccode"] as? String,
              let geetest_challenge = result?["geetest_challenge"] as? String,
              let geetest_validate = result?["geetest_validate"] as? String
        else {
            return
        }

        reserveName(
            geetest_seccode: geetest_seccode,
            geetest_challenge: geetest_challenge,
            geetest_validate: geetest_validate
        )
    }

    func shouldUseDefaultSecondaryValidate(_: GT3CaptchaManager) -> Bool {
        false
    }

    func gtCaptcha(
        _: GT3CaptchaManager,
        didReceiveSecondaryCaptchaData _: Data?,
        response _: URLResponse?,
        error _: GT3Error?,
        decisionHandler _: @escaping (GT3SecondaryCaptchaPolicy) -> Void
    ) {}
}
