//
//  EnterSeed.ViewModel.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 11.11.2021.
//

import Combine
import Foundation
import SolanaSwift

protocol EnterSeedViewModelType: AnyObject {
    var maxWordsCount: Int { get }
    var navigationPublisher: AnyPublisher<EnterSeed.NavigatableScene?, Never> { get }
    var errorPublisher: AnyPublisher<String?, Never> { get }
    var seedTextSubject: CurrentValueSubject<String?, Never> { get }
    var seedTextPublisher: AnyPublisher<String?, Never> { get }
    var mainButtonContentPublisher: AnyPublisher<EnterSeed.MainButtonContent, Never> { get }

    func showInfo()
    func goForth()
    func showTermsAndConditions()
}

private enum Constants {
    static let maxWordsCount = 24
}

extension EnterSeed {
    @MainActor
    final class ViewModel: ObservableObject {
        // MARK: - Dependencies

        // MARK: - Properties

        private var subscriptions = [AnyCancellable]()

        // MARK: - Subject

        @Published private var navigatableScene: NavigatableScene?
        @Published private var error: String?
        @Published private var mainButtonContent = EnterSeed.MainButtonContent.invalid(.empty)

        let seedTextSubject = CurrentValueSubject<String?, Never>(nil)
        let maxWordsCount = Constants.maxWordsCount

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
                .assign(to: \.mainButtonContent, on: self)
                .store(in: &subscriptions)

            seedTextSubject
                .map { _ in nil }
                .assign(to: \.error, on: self)
                .store(in: &subscriptions)
        }

        private func phraseError(in words: [String]) -> String? {
            guard words.count >= 12 else {
                return L10n.seedPhraseMustHaveAtLeast12Words
            }

            do {
                _ = try Mnemonic(phrase: words)
            } catch {
                return L10n.TheWrongSecurityKeyOrWordsOrder.pleaseTryAgain
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
    var navigationPublisher: AnyPublisher<EnterSeed.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String?, Never> {
        $error.eraseToAnyPublisher()
    }

    var mainButtonContentPublisher: AnyPublisher<EnterSeed.MainButtonContent, Never> {
        $mainButtonContent.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func goForth() {
        let words = getSeedWords()

        if let error = phraseError(in: words) {
            mainButtonContent = .invalid(.error)
            self.error = error
            return
        }

        navigatableScene = .success(words: words)
    }

    func showInfo() {
        navigatableScene = .info
    }

    func showTermsAndConditions() {
        navigatableScene = .termsAndConditions
    }

    var seedTextPublisher: AnyPublisher<String?, Never> {
        seedTextSubject.eraseToAnyPublisher()
    }
}
