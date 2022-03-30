//
//  EnterSeed.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 11.11.2021.
//

import Foundation
import RxCocoa
import RxSwift
import SolanaSwift

protocol EnterSeedViewModelType: AnyObject {
    var navigationDriver: Driver<EnterSeed.NavigatableScene?> { get }
    var errorDriver: Driver<String?> { get }
    var seedTextSubject: BehaviorRelay<String?> { get }
    var seedTextDriver: Driver<String?> { get }
    var mainButtonContentDriver: Driver<EnterSeed.MainButtonContent> { get }

    func showInfo()
    func goForth()
    func showTermsAndConditions()
}

extension EnterSeed {
    final class ViewModel {
        // MARK: - Dependencies

        // MARK: - Properties

        private let disposeBag = DisposeBag()

        // MARK: - Subject

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let errorSubject = BehaviorRelay<String?>(value: nil)
        private let mainButtonContentSubject = BehaviorRelay<EnterSeed.MainButtonContent>(value: .invalid(.empty))

        let seedTextSubject = BehaviorRelay<String?>(value: nil)

        init() {
            bind()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        private func bind() {
            seedTextSubject
                .map {
                    $0?.isEmpty ?? true
                        ? .invalid(.empty)
                        : .valid
                }
                .bind { [weak self] in
                    self?.mainButtonContentSubject.accept($0)
                }
                .disposed(by: disposeBag)

            seedTextSubject
                .bind { [weak self] _ in
                    self?.errorSubject.accept(nil)
                }
                .disposed(by: disposeBag)
        }

        private func phraseError(in words: [String]) -> String? {
            guard words.count >= 12 else {
                return L10n.seedPhraseMustHaveAtLeast12Words
            }

            do {
                _ = try Mnemonic(phrase: words)
            } catch {
                return L10n.wrongOrderOrSeedPhrasePleaseCheckItAndTryAgain
            }

            return nil
        }

        private func getSeedWords() -> [String] {
            seedTextSubject.value?
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                ?? []
        }
    }
}

extension EnterSeed.ViewModel: EnterSeedViewModelType {
    var navigationDriver: Driver<EnterSeed.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorSubject.asDriver()
    }

    var mainButtonContentDriver: Driver<EnterSeed.MainButtonContent> {
        mainButtonContentSubject.asDriver()
    }

    // MARK: - Actions

    func goForth() {
        let words = getSeedWords()

        if let error = phraseError(in: words) {
            mainButtonContentSubject.accept(.invalid(.error))
            return errorSubject.accept(error)
        }

        navigationSubject.accept(.success(words: words))
    }

    func showInfo() {
        navigationSubject.accept(.info)
    }

    func showTermsAndConditions() {
        navigationSubject.accept(.termsAndConditions)
    }

    var seedTextDriver: Driver<String?> {
        seedTextSubject.asDriver()
    }
}
