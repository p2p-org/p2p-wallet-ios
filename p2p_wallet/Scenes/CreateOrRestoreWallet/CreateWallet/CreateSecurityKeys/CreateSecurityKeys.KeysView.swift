//
// Created by Giang Long Tran on 04.11.21.
//

import Foundation
import BECollectionView
import RxSwift
import RxCocoa

extension CreateSecurityKeys {
    private class KeyView: BEView {
        var key: String = "" {
            didSet {
                update()
            }
        }
        
        var index: Int = 0 {
            didSet {
                update()
            }
        }
        
        private let textLabel: UILabel = UILabel(weight: .medium, textAlignment: .center)
        
        init(index: Int, key: String) {
            self.index = index
            self.key = key
            
            super.init(frame: CGRect.zero)
        }
        
        override func commonInit() {
            super.commonInit()
            
            layer.borderColor = UIColor.f2f2f7.cgColor
            layer.borderWidth = 1
            layer.cornerRadius = 8
            layer.masksToBounds = true
            
            addSubview(textLabel)
            textLabel.autoPinEdgesToSuperviewEdges()
            
            update()
        }
        
        private func update() {
            let attrText = NSMutableAttributedString()
                .text("\(index). ", size: 15, weight: .medium, color: .h8e8e93)
                .text("\(key)", size: 15)
            
            textLabel.attributedText = attrText
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class KeysView: BEView {
        var keys: [String] = [] {
            didSet {
                update()
            }
        }
        
        private let numberOfColumns: Int = 3
        private let spacing: CGFloat = 8
        private let runSpacing: CGFloat = 8
        private let keyHeight: CGFloat = 37
        
        lazy private var content = UIStackView(axis: .vertical, spacing: runSpacing, alignment: .fill, distribution: .fillEqually)
        
        override func commonInit() {
            super.commonInit()
            layout()
            update()
        }
        
        func layout() {
            addSubview(content)
            content.autoPinEdgesToSuperviewEdges()
        }
        
        func update() {
            content.removeAllArrangedSubviews()
            keys.chunked(into: numberOfColumns).enumerated().forEach { section, chunk in
                let row = UIStackView(axis: .horizontal, spacing: spacing, alignment: .fill, distribution: .fillEqually)
                row.heightAnchor.constraint(equalToConstant: keyHeight).isActive = true
                row.addArrangedSubviews(chunk.enumerated().map { index, key in
                    KeyView(index: section * numberOfColumns + index + 1, key: key)
                })
                content.addArrangedSubview(row)
            }
        }
    }
    
    class KeysViewActions: BEView {
        lazy private var content = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually)
        
        fileprivate let copyButton: UIButton = UIButton.text(text: L10n.copy, image: .copyIcon, tintColor: .h5887ff)
        fileprivate let saveButton: UIButton = UIButton.text(text: L10n.save, image: .imageIcon, tintColor: .h5887ff)
        fileprivate let refreshButton: UIButton = UIButton.text(text: L10n.renew, image: .refreshIcon, tintColor: .h5887ff)
        
        override func commonInit() {
            super.commonInit()
            layout()
        }
        
        func layout() {
            addSubview(content)
            content.addArrangedSubviews {
                copyButton
                saveButton
                refreshButton
            }
            content.autoPinEdgesToSuperviewEdges()
            content.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        
    }
}

extension Reactive where Base: CreateSecurityKeys.KeysView {
    var keys: Binder<[String]> {
        Binder(base) { view, keys in
            view.keys = keys
        }
    }
}

extension Reactive where Base: CreateSecurityKeys.KeysViewActions {
    var onCopy: ControlEvent<Void> {
        base.copyButton.rx.tap
    }
    
    var onSave: ControlEvent<Void> {
        base.saveButton.rx.tap
    }
    
    var onRefresh: ControlEvent<Void> {
        base.refreshButton.rx.tap
    }
}