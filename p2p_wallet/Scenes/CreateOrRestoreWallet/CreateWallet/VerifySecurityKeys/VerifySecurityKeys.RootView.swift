//
//  VerifySecurityKeys.RootView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.11.21.
//

import Combine
import UIKit

extension VerifySecurityKeys {
    class RootView: BEView {
        // MARK: - Constants

        var subscriptions = [AnyCancellable]()

        // MARK: - Properties

        private let viewModel: VerifySecurityKeysViewModelType

        // MARK: - Subviews

        private let questionsView: QuestionsView = .init()
        private let nextButton: NextButton = .init()

        // MARK: - Methods

        init(viewModel: VerifySecurityKeysViewModelType) {
            self.viewModel = viewModel
            super.init(frame: CGRect.zero)
        }

        override func commonInit() {
            super.commonInit()
            layout()
            bind()

            #if DEBUG
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
                    self?.viewModel.autoAnswerToAllQuestions()
                }
            #endif
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
        }

        // MARK: - Layout

        private func layout() {
            addSubview(questionsView)
            questionsView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)
            questionsView.autoPinEdge(toSuperviewSafeArea: .top)

            addSubview(nextButton)
            nextButton.autoPinEdgesToSuperviewSafeArea(
                with: .init(top: 0, left: 18, bottom: 20, right: 18),
                excludingEdge: .top
            )
        }

        private func bind() {
            viewModel.questionsPublisher
                .assign(to: \.questions, on: questionsView)
                .store(in: &subscriptions)
            viewModel.validationPublisher
                .assign(to: \.ready, on: nextButton)
                .store(in: &subscriptions)
            viewModel.validationPublisher.map {
                $0 == true ? L10n.saveContinue : L10n.chooseTheCorrectWords
            }
            .assign(to: \.text, on: nextButton)
            .store(in: &subscriptions)

            viewModel.validationPublisher
                .map {
                    $0 == true ? UIImage.checkMark : nil
                }
                .assign(to: \.image, on: nextButton)
                .store(in: &subscriptions)

            nextButton.onTap(self, action: #selector(verify))

            questionsView.delegate = self
        }

        @objc func verify() {
            viewModel.verify()
        }
    }
}

extension VerifySecurityKeys.RootView: QuestionsDelegate {
    func giveAnswer(question: VerifySecurityKeys.Question, answer: String) {
        viewModel.answer(question: question, answer: answer)
    }
}
