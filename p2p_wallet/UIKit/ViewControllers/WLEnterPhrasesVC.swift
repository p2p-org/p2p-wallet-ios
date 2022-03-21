//
//  WLEnterPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import Foundation
import RxCocoa
import RxSwift
import SubviewAttachingTextView

class WLEnterPhrasesVC: BaseVC, WLPhrasesTextViewDelegate {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }

    // MARK: - Properties

    var completion: (([String]) -> Void)?
    let error = BehaviorRelay<Error?>(value: nil)
    var dismissAfterCompletion = true

    // MARK: - Subviews

    lazy var scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: .init(only: .bottom, inset: 40))
    lazy var stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill)

    lazy var textView = WLPhrasesTextView()

    lazy var errorLabel = UILabel(textColor: .alert, numberOfLines: 0, textAlignment: .center)

    lazy var tabBar: TabBar = {
        let tabBar = TabBar(cornerRadius: 20, contentInset: .init(x: 20, y: 10))
        tabBar.backgroundColor = .h2f2f2f
        tabBar.stackView.addArrangedSubviews([
            pasteButton,
            UIView.spacer,
            nextButton,
        ])
        return tabBar
    }()

    lazy var nextButton = WLButton(backgroundColor: .h5887ff, cornerRadius: 12, label: L10n.done, labelFont: .systemFont(ofSize: 15, weight: .semibold), textColor: .white, contentInsets: .init(x: 16, y: 10))
        .onTap(self, action: #selector(buttonNextDidTouch))
    lazy var pasteButton = WLButton(backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12, label: L10n.paste, labelFont: .systemFont(ofSize: 15, weight: .semibold), textColor: .white, contentInsets: .init(x: 16, y: 10))
        .onTap(self, action: #selector(buttonPasteDidTouch))
    lazy var retryButton = WLButton.stepButton(type: .gray, label: L10n.resetAndTryAgain)
        .onTap(self, action: #selector(resetAndTryAgainButtonDidTouch))

    lazy var descriptionLabel = UILabel(text: L10n.enterASeedPhraseFromYourAccount, textSize: 17, textColor: .textSecondary.onDarkMode(.h5887ff), numberOfLines: 0, textAlignment: .center)

    // MARK: - Initializers

    override func setUp() {
        super.setUp()

        // scroll view for flexible height
        view.addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        scrollView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()

        // stackView
        scrollView.contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()

        // arranged subviews
        stackView.addArrangedSubviews {
            textView
                .padding(.init(all: 10), backgroundColor: .f3f3f3.onDarkMode(.h1b1b1b), cornerRadius: 16)
                .border(width: 1, color: .a3a5ba.onDarkMode(.h5887ff))
                .padding(.init(all: 20, excludingEdge: .bottom))
            BEStackViewSpacing(30)
            errorLabel
                .padding(.init(x: 20, y: 0))
        }

        // tabBar
        view.addSubview(tabBar)
        tabBar.autoPinEdge(toSuperviewEdge: .leading)
        tabBar.autoPinEdge(toSuperviewEdge: .trailing)
        tabBar.autoPinBottomToSuperViewAvoidKeyboard()

        view.addSubview(descriptionLabel)
        descriptionLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
        descriptionLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
        descriptionLabel.autoPinEdge(.bottom, to: .bottom, of: tabBar, withOffset: -20)

        view.addSubview(retryButton)
        retryButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 20)
        retryButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 20)
        retryButton.autoPinEdge(.bottom, to: .top, of: descriptionLabel, withOffset: -30)

        textView.becomeFirstResponder()
        textView.keyboardDismissMode = .onDrag
        textView.forwardedDelegate = self
    }

    override func bind() {
        super.bind()
        Observable.combineLatest(
            textView.rx.text
                .map { [weak self] _ in self?.textView.getPhrases().isEmpty == false },
            error.map { $0 == nil }
        )
        .map { $0 && $1 }
        .asDriver(onErrorJustReturn: false)
        .drive(nextButton.rx.isEnabled)
        .disposed(by: disposeBag)

        let errorDriver = error.asDriver(onErrorJustReturn: nil)

        errorDriver
            .map { error -> String? in
                if error == nil { return nil }
                return L10n.wrongOrderOrSeedPhrasePleaseCheckItAndTryAgain
            }
            .drive(errorLabel.rx.text)
            .disposed(by: disposeBag)

        errorDriver
            .map { $0 == nil }
            .drive(retryButton.rx.isHidden)
            .disposed(by: disposeBag)

        errorDriver
            .map { $0 == nil }
            .drive(descriptionLabel.rx.isHidden)
            .disposed(by: disposeBag)

        errorDriver
            .map { $0 != nil }
            .drive(tabBar.rx.isHidden)
            .disposed(by: disposeBag)
    }

    @objc func buttonNextDidTouch() {
        textView.wrapPhrase()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.handlePhrases()
        }
    }

    @objc func buttonPasteDidTouch() {
        textView.paste(nil)
    }

    @objc func resetAndTryAgainButtonDidTouch() {
        textView.clear()
        textView.becomeFirstResponder()
    }

    private func handlePhrases() {
        hideKeyboard()
        textView.superview?.border(width: 1, color: .f3f3f3.onDarkMode(.h1b1b1b))
        do {
            let phrases = textView.getPhrases()
            if phrases.count < 12 {
                throw SolanaSDK.Error.other(L10n.seedPhraseMustHaveAtLeast12Words)
            }
            _ = try Mnemonic(phrase: phrases.filter { !$0.isEmpty })
            if dismissAfterCompletion {
                dismiss(animated: true) { [weak self] in
                    self?.completion?(phrases)
                }
            } else {
                completion?(phrases)
            }

        } catch {
            self.error.accept(error)
        }
    }

    func wlPhrasesTextViewDidBeginEditing(_ textView: WLPhrasesTextView) {
        error.accept(nil)
        textView.superview?.border(width: 1, color: .h5887ff)
    }

    func wlPhrasesTextViewDidEndEditing(_ textView: WLPhrasesTextView) {
        textView.superview?.border(width: 1, color: .f3f3f3.onDarkMode(.h1b1b1b))
    }

    func wlPhrasesTextViewDidChange(_ textView: WLPhrasesTextView) {
        if textView.isFirstResponder {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self, weak textView] in
                guard let range = textView?.selectedTextRange?.start,
                      let rect = textView?.caretRect(for: range)
                else { return }
                self?.scrollView.scrollTo(y: rect.maxY, animated: true)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
                self?.scrollView.scrollToBottom(animated: true)
            }
        }
    }
}
