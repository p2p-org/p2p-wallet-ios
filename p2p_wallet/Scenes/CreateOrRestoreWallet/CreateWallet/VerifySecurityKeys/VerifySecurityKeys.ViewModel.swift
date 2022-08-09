//
//  VerifySecurityKeys.ViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.11.21.
//

import Combine
import Foundation

protocol VerifySecurityKeysViewModelType {
    var navigationPublisher: AnyPublisher<VerifySecurityKeys.NavigatableScene?, Never> { get }
    var questionsPublisher: AnyPublisher<[VerifySecurityKeys.Question], Never> { get }
    var validationPublisher: AnyPublisher<Bool, Never> { get }

    func generate()
    func answer(question: VerifySecurityKeys.Question, answer: String)
    func back()
    func verify() async

    #if DEBUG
        func autoAnswerToAllQuestions()
    #endif
}

extension VerifySecurityKeys {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        private let createWalletViewModel: CreateWalletViewModelType

        // MARK: - Properties

        let keyPhrase: [String]

        // MARK: - Subject

        @Published private var navigatableScene: NavigatableScene?
        @Published private var questions = [Question]()

        init(keyPhrase: [String], createWalletViewModel: CreateWalletViewModelType) {
            self.keyPhrase = keyPhrase
            self.createWalletViewModel = createWalletViewModel
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
    }
}

extension VerifySecurityKeys.ViewModel: VerifySecurityKeysViewModelType {
    var validationPublisher: AnyPublisher<Bool, Never> {
        $questions
            .map { questions -> Bool in
                for question in questions where question.answer == nil {
                    return false
                }
                return true
            }
            .eraseToAnyPublisher()
    }

    var navigationPublisher: AnyPublisher<VerifySecurityKeys.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var questionsPublisher: AnyPublisher<[VerifySecurityKeys.Question], Never> {
        $questions.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func generate() {
        let questions = keyPhrase.randomElements(length: 4).map { index, key -> VerifySecurityKeys.Question in
            let answers = [key] + keyPhrase.randomElements(length: 2, exclude: [key]).map { $1 }
            return VerifySecurityKeys.Question(index: index, variants: answers.shuffled())
        }

        self.questions = questions
    }

    func answer(question: VerifySecurityKeys.Question, answer: String) {
        let index = questions.firstIndex(where: { $0 == question })
        guard let index = index else { return }

        var questions = questions
        questions[index] = question.give(answer: answer)

        self.questions = questions
    }

    func verify() async {
        let questions = questions
        for question in questions where question.answer == nil { return }

        for question in questions where question.answer != keyPhrase[question.index] {
            navigatableScene = .onMistake
            return
        }

        await createWalletViewModel.handlePhrases(keyPhrase)
    }

    func back() {
        createWalletViewModel.back()
    }

    #if DEBUG
        func autoAnswerToAllQuestions() {
            for question in questions {
                answer(question: question, answer: keyPhrase[question.index])
            }
        }
    #endif
}

private extension Array where Element: Equatable {
    func randomElements(length: Int, exclude: [Element] = []) -> ArraySlice<(offset: Int, element: Element)> {
        enumerated()
            .filter { _, element in !exclude.contains(where: { $0 == element }) }
            .shuffled()
            .prefix(length)
    }
}
