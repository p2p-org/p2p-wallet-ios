//
//  VerifySecurityKeys.RootView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.11.21.
//

import RxSwift
import UIKit

extension VerifySecurityKeys {
    class RootView: BEView {
        // MARK: - Constants

        let disposeBag = DisposeBag()

        // MARK: - Properties

        private let viewModel: VerifySecurityKeysViewModelType

        // MARK: - Subviews

        private let navigationBar: WLNavigationBar = {
            let navigationBar = WLNavigationBar(forAutoLayout: ())
            navigationBar.titleLabel.text = L10n.verifyYourSecurityKey
            return navigationBar
        }()

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
            addSubview(navigationBar)
            navigationBar.autoPinEdge(toSuperviewSafeArea: .top)
            navigationBar.autoPinEdge(toSuperviewEdge: .leading)
            navigationBar.autoPinEdge(toSuperviewEdge: .trailing)

            addSubview(questionsView)
            questionsView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)
            questionsView.autoPinEdge(.top, to: .bottom, of: navigationBar)

            addSubview(nextButton)
            nextButton.autoPinEdgesToSuperviewSafeArea(with: .init(top: 0, left: 18, bottom: 20, right: 18), excludingEdge: .top)
        }

        private func bind() {
            navigationBar.backButton.onTap(self, action: #selector(back))
            viewModel.questionsDriver.drive(questionsView.rx.questions).disposed(by: disposeBag)
            viewModel.validationDriver.drive(nextButton.rx.ready).disposed(by: disposeBag)
            viewModel.validationDriver.map {
                $0 == true ? L10n.saveContinue : L10n.chooseTheCorrectWords
            }.drive(nextButton.rx.text).disposed(by: disposeBag)
            viewModel.validationDriver.map {
                $0 == true ? UIImage.checkMark : nil
            }.drive(nextButton.rx.image).disposed(by: disposeBag)

            nextButton.onTap(self, action: #selector(verify))

            questionsView.delegate = self
        }

        @objc func verify() {
            viewModel.verify()
        }

        @objc func back() {
            viewModel.back()
        }
    }
}

extension VerifySecurityKeys.RootView: QuestionsDelegate {
    func giveAnswer(question: VerifySecurityKeys.Question, answer: String) {
        viewModel.answer(question: question, answer: answer)
    }
}
