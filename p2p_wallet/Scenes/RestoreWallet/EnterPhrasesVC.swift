//
//  EnterPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2020.
//

import Foundation
import UITextView_Placeholder
import SubviewAttachingTextView

class EnterPhrasesVC: WLModalWrapperVC {
    override var padding: UIEdgeInsets {super.padding.modifying(dLeft: .defaultPadding, dRight: .defaultPadding)}
    
    init() {
        let vc = _EnterPhrasesVC()
        super.init(wrapped: vc)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomView.backgroundColor = .h2f2f2f
    }
    
    override func setUp() {
        super.setUp()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.addArrangedSubviews([
            UIImageView(width: 24, height: 24, image: .securityKey, tintColor: .white),
            UILabel(text: L10n.securityKeys.uppercaseFirst, textSize: 21, weight: .semibold)
        ])
        
        let separator = UIView.separator(height: 1, color: .separator)
        containerView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }
}

class _EnterPhrasesVC: BaseVStackVC {
    override var padding: UIEdgeInsets {.init(all: 20)}
    
    lazy var textView: SubviewAttachingTextView = {
        let tv = SubviewAttachingTextView(forExpandable: ())
        tv.backgroundColor = .clear
        tv.font = .systemFont(ofSize: 15)
        tv.typingAttributes = [.font: UIFont.systemFont(ofSize: 15)]
        tv.heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
            .isActive = true
        tv.placeholder = L10n.enterSeedPhrasesInACorrectOrderToRecoverYourWallet
        tv.delegate = self
        tv.autocapitalizationType = .none
        tv.autocorrectionType = .no
        return tv
    }()
    
    lazy var tabBar: TabBar = {
        let tabBar = TabBar(cornerRadius: 20, contentInset: .init(x: 20, y: 10))
        tabBar.backgroundColor = .h2f2f2f
        tabBar.stackView.addArrangedSubviews([
            pasteButton,
            UIView.spacer,
            nextButton
        ])
        return tabBar
    }()
    
    lazy var nextButton = WLButton(backgroundColor: .h5887ff, cornerRadius: 12, label: L10n.done, labelFont: .systemFont(ofSize: 15, weight: .semibold), textColor: .white, contentInsets: .init(x: 16, y: 10))
        .onTap(self, action: #selector(buttonNextDidTouch))
    lazy var pasteButton = WLButton(backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12, label: L10n.paste, labelFont: .systemFont(ofSize: 15, weight: .semibold), textColor: .white, contentInsets: .init(x: 16, y: 10))
        .onTap(self, action: #selector(buttonPasteDidTouch))
    
    override func setUp() {
        super.setUp()
        title = L10n.enterSecurityKeys
        stackView.addArrangedSubview(
            textView
                .padding(.init(all: 16), backgroundColor: .lightGrayBackground, cornerRadius: 16)
                .border(width: 1, color: .a3a5ba)
        )
        
        // tabBar
        view.addSubview(tabBar)
        tabBar.autoPinEdge(toSuperviewEdge: .leading)
        tabBar.autoPinEdge(toSuperviewEdge: .trailing)
        tabBar.autoPinBottomToSuperViewAvoidKeyboard()
        
        textView.becomeFirstResponder()
    }
    
    override func bind() {
        super.bind()
        textView.rx.text
            .map {_ in !self.getPhrasesInTextView().isEmpty}
            .asDriver(onErrorJustReturn: false)
            .drive(nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    @objc func buttonNextDidTouch() {
        wrapPhrase()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.handlePhrases()
        }
    }
    
    @objc func buttonPasteDidTouch() {
        textView.paste(nil)
    }
    
    private func handlePhrases()
    {
        do {
            let phrases = getPhrasesInTextView()
            _ = try Mnemonic(phrase: phrases.filter {!$0.isEmpty})
            let nc = BENavigationController(rootViewController: WelcomeBackVC(phrases: phrases))
            UIApplication.shared.changeRootVC(to: nc)
        } catch {
            showError(error)
        }
    }
    
    private func getPhrasesInTextView() -> [String] {
        var phrases = [String]()
        textView.attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textView.attributedText.length)) { (att, _, _) in
            if let att = att as? Attachment, let phrase = att.phrase {
                phrases.append(phrase)
            }
        }
        return phrases
    }
}

extension _EnterPhrasesVC: UITextViewDelegate {
    class Attachment: SubviewTextAttachment {
        var phrase: String?
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // if deleting
        if text.isEmpty { return true }
        
        // prevent dupplicated spaces
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            // prevent space at the begining
            if range.location == 0 {return false}
            // prevent 2 spaces next to each other
            else if textView.attributedText.attributedSubstring(from: NSRange(location: range.location - 1, length: 1)).string == " " {
                return false
            }
        }
        
        // ignore invalid characters
        let invalidCharactersSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz ").inverted
        
        if text.lowercased().rangeOfCharacter(from: invalidCharactersSet) == nil {
            // wrap phrase when found a space
            if text.contains(" ") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.wrapPhrase()
                }
            }
            return true
        }
        return false
    }
    
    fileprivate func wrapPhrase() {
        // get all phrases
        let phrases = textView.text.components(separatedBy: " ")
        
        // get length's difference after replacing text with attachment
        var lengthDiff = 0
        var selectedLocation = textView.selectedRange.location
        
        for phrase in phrases.map({$0.replacingOccurrences(of: "\u{fffc}", with: "")}).filter({!$0.isEmpty}) {
            let text = textView.text as NSString
            let range = text.range(of: phrase)
            
            // add attachment
            textView.textStorage.replaceCharacters(in: range, with: attachment(phrase: phrase))
            
            // diff of length, length become 1 when inserting attachment
            lengthDiff = 1 - phrase.count
            
            if selectedLocation > range.location {
                selectedLocation += lengthDiff
            }
        }
        // re-arrange attachment's order
        var count = 0
        textView.attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textView.attributedText.length)) { (att, range, _) in
            if let att = att as? Attachment, let phrase = att.phrase {
                count += 1
                textView.textStorage.replaceCharacters(in: range, with: attachment(phrase: phrase, index: count))
            }
        }
        
        // recalculate selected range
        DispatchQueue.main.async {
            self.textView.selectedRange = NSRange(location: selectedLocation, length: 0)
        }
    }
    
    fileprivate func attachment(phrase: String, index: Int? = nil) -> NSAttributedString {
        let phrase = phrase.lowercased()
        // replace phrase's range by attachment that is a uilabel
        let label = UILabel(text: (index != nil ? "\(index!). " : "" ) + phrase, textSize: 15, textColor: .white)
            .padding(.init(x: 10, y: 6), backgroundColor: .h5887ff, cornerRadius: 5)
        label.translatesAutoresizingMaskIntoConstraints = true
        
        // replace text by attachment
        let attachment = Attachment(view: label)
        attachment.phrase = phrase
        let attrString = NSMutableAttributedString(attachment: attachment)
        attrString.addAttributes(textView.typingAttributes, range: NSRange(location: 0, length: attrString.length))
        return attrString
    }
}
