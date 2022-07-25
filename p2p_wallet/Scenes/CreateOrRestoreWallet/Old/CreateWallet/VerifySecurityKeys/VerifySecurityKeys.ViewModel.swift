//
//  VerifySecurityKeys.ViewModel.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.11.21.
//

import Foundation
import RxCocoa
import RxSwift

protocol VerifySecurityKeysViewModelType {
    var navigationDriver: Driver<VerifySecurityKeys.NavigatableScene?> { get }
    var questionsDriver: Driver<[VerifySecurityKeys.Question]> { get }
    var validationDriver: Driver<Bool> { get }

    func generate()
    func answer(question: VerifySecurityKeys.Question, answer: String)
    func back()
    func verify()

    #if DEBUG
        func autoAnswerToAllQuestions()
    #endif
}

extension VerifySecurityKeys {
    class ViewModel {
        // MARK: - Dependencies

        private let createWalletViewModel: CreateWalletViewModelType

        // MARK: - Properties

        let keyPhrase: [String]

        // MARK: - Subject

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let questionsSubject = BehaviorRelay<[Question]>(value: [])

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
    var validationDriver: Driver<Bool> {
        questionsSubject.asDriver().map { questions -> Bool in
            for question in questions where question.answer == nil {
                return false
            }
            return true
        }
    }

    var navigationDriver: Driver<VerifySecurityKeys.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var questionsDriver: Driver<[VerifySecurityKeys.Question]> {
        questionsSubject.asDriver()
    }

    // MARK: - Actions

    func generate() {
        let questions = keyPhrase.randomElements(length: 4).map { index, key -> VerifySecurityKeys.Question in
            let answers = [key] + keyPhrase.randomElements(length: 2, exclude: [key]).map { $1 }
            return VerifySecurityKeys.Question(index: index, variants: answers.shuffled())
        }

        questionsSubject.accept(questions)
    }

    func answer(question: VerifySecurityKeys.Question, answer: String) {
        let index = questionsSubject.value.firstIndex(where: { $0 == question })
        guard let index = index else { return }

        var questions = questionsSubject.value
        questions[index] = question.give(answer: answer)

        questionsSubject.accept(questions)
    }

    func verify() {
        let questions = questionsSubject.value
        for question in questions where question.answer == nil { return }

        for question in questions where question.answer != keyPhrase[question.index] {
            navigationSubject.accept(.onMistake)
            return
        }

        createWalletViewModel.handlePhrases(keyPhrase)
    }

    func back() {
        createWalletViewModel.back()
    }

    #if DEBUG
        func autoAnswerToAllQuestions() {
            for question in questionsSubject.value {
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
