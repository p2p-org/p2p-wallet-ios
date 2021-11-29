//
//  CreateOrRestoreReserveName.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 26.11.2021.
//

import Foundation
import RxSwift
import RxCocoa
import GT3Captcha
import UIKit

protocol NewReserveNameViewModelType: AnyObject {
    var navigationDriver: Driver<CreateOrRestoreReserveName.NavigatableScene?> { get }
    var textFieldStateDriver: Driver<CreateOrRestoreReserveName.TextFieldState> { get }
    var mainButtonStateDriver: Driver<CreateOrRestoreReserveName.MainButtonState> { get }
    var textFieldTextSubject: BehaviorRelay<String?> { get }
    var isLoadingDriver: Driver<Bool> { get }

    func showTermsOfUse()
    func showPrivacyPolicy()
    func skipButtonPressed()
    func goBack()
    func goForth()
}

extension CreateOrRestoreReserveName {
    class ViewModel: NSObject {
        // MARK: - Dependencies
        private let nameService: NameServiceType
        private let owner: String
        private let reserveNameHandler: ReserveNameHandler
        private lazy var manager: GT3CaptchaManager = {
            let manager = GT3CaptchaManager(
                api1: nameService.captchaAPI1Url,
                api2: nil,
                timeout: 10
            )
            manager.delegate = self
            return manager
        }()

        // MARK: - Properties
        private let disposeBag = DisposeBag()

        private var nameAvailabilityDisposable: Disposable?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let textFieldStateSubject = BehaviorRelay<TextFieldState>(value: .empty)
        private let mainButtonStateSubject = BehaviorRelay<CreateOrRestoreReserveName.MainButtonState>(value: .empty)
        let textFieldTextSubject = BehaviorRelay<String?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)

        init(
            owner: String,
            nameService: NameServiceType,
            reserveNameHandler: ReserveNameHandler
        ) {
            self.nameService = nameService
            self.owner = owner
            self.reserveNameHandler = reserveNameHandler
            
            super.init()

            bind()
            manager.registerCaptcha(nil)
        }

        private func bind() {
            textFieldTextSubject
                .subscribe { [weak self] in
                    self?.checkUsernameForAvailability(string: $0)
                }
                .disposed(by: disposeBag)
        }

        private func checkUsernameForAvailability(string: String?) {
            nameAvailabilityDisposable?.dispose()

            guard let string = string, !string.isEmpty else {
                return setEmptyState()
            }

            nameAvailabilityDisposable = nameService.isNameAvailable(string)
                .subscribe(onSuccess: {  [weak self] in
                    let state: TextFieldState = $0 ? .available(name: string) : .unavailable(name: string)
                    self?.textFieldStateSubject.accept(state)
                    self?.mainButtonStateSubject.accept($0 ? .canContinue : .unavailableUsername)
                })
        }

        private func setEmptyState() {
            textFieldStateSubject.accept(.empty)
            mainButtonStateSubject.accept(.empty)
        }

        private func reserveName(
            geetest_seccode: String,
            geetest_challenge: String,
            geetest_validate: String
        ) {
            guard let name = textFieldTextSubject.value else { return }

            startLoading()
            nameService
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
                .subscribe(onSuccess: { [weak self] _ in
                    self?.stopLoading()
                    self?.nameDidReserve(name)
                }, onFailure: { [weak self] error in
                    self?.stopLoading()
                    UIApplication.shared.showToast(message: "❌ \(error.readableDescription)")
                })
                .disposed(by: disposeBag)
        }

        private func nameDidReserve(_ name: String) {
            reserveNameHandler.handleName(name)
        }

        private func startLoading() {
            isLoadingSubject.accept(true)
        }

        private func stopLoading() {
            isLoadingSubject.accept(false)
        }

        private func handleSkipAlertAction(isProceed: Bool) {
            if isProceed {
                skip()
            }
        }

        private func skip() {
            reserveNameHandler.handleName(nil)
        }
    }
}

extension CreateOrRestoreReserveName.ViewModel: NewReserveNameViewModelType {
    func skipButtonPressed() {
        navigationSubject.accept(
            .skipAlert({ [weak self] in
                self?.handleSkipAlertAction(isProceed: $0)
            })
        )
    }

    var navigationDriver: Driver<CreateOrRestoreReserveName.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var textFieldStateDriver: Driver<CreateOrRestoreReserveName.TextFieldState> {
        textFieldStateSubject.asDriver()
    }

    var mainButtonStateDriver: Driver<CreateOrRestoreReserveName.MainButtonState> {
        mainButtonStateSubject.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }

    func goForth() {
        manager.startGTCaptchaWith(animated: true)
    }

    func goBack() {
        navigationSubject.accept(.back)
    }

    func showTermsOfUse() {
        navigationSubject.accept(.termsOfUse)
    }

    func showPrivacyPolicy() {
        navigationSubject.accept(.privacyPolicy)
    }
}

extension CreateOrRestoreReserveName.ViewModel: GT3CaptchaManagerDelegate {
    func gtCaptcha(_ manager: GT3CaptchaManager, errorHandler error: GT3Error) {
        UIApplication.shared.showToast(message: "❌ \(error.readableDescription)")
    }

    func gtCaptcha(_ manager: GT3CaptchaManager, didReceiveCaptchaCode code: String, result: [AnyHashable: Any]?, message: String?) {
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

    func shouldUseDefaultSecondaryValidate(_ manager: GT3CaptchaManager) -> Bool {
        false
    }

    func gtCaptcha(_ manager: GT3CaptchaManager, didReceiveSecondaryCaptchaData data: Data?, response: URLResponse?, error: GT3Error?, decisionHandler: @escaping (GT3SecondaryCaptchaPolicy) -> Void) {

    }
}
