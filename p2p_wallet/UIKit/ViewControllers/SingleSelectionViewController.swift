//
//  SingleSelectionViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import Foundation

class SingleSelectionViewController<Option: Equatable>: WLIndicatorModalVC, CustomPresentableViewController {
    // MARK: - Properties

    var transitionManager: UIViewControllerTransitioningDelegate?
    override var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    private let options: [Option]
    private let selectView: SelectOptionView<Option>
    private lazy var doneButton = WLButton.stepButton(type: .blue, label: L10n.done)
        .onTap(self, action: #selector(buttonDoneDidTouch))
    public var completion: ((Option) -> Void)?

    // MARK: - Subviews

    private lazy var titleLabel = UILabel(text: title, textSize: 17, weight: .semibold)
    private lazy var backButton = UIImageView(width: 10.72, height: 17.52, image: .backArrow, tintColor: .textBlack)
        .padding(.init(x: 6, y: 0))
        .onTap(self, action: #selector(back))
    private lazy var headerView: UIView = {
        let headerView = UIView(forAutoLayout: ())
        let stackView = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
            backButton
            titleLabel
        }
        headerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 20))
        let separator = UIView.defaultSeparator()
        headerView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .init(all: 0), excludingEdge: .top)
        return headerView
    }()

    lazy var stackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
        headerView
    }

    // MARK: - Initializer

    init(title: String, options: [Option], selectedOption: Option, cellBuilder: @escaping ((Option, Bool) -> OptionViewType)) {
        self.options = options
        selectView = .init(options: options, selectedIndex: options.firstIndex(of: selectedOption)!, cellBuilder: cellBuilder)
        super.init()
        self.title = title
    }

    override func setUp() {
        super.setUp()
        containerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        stackView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()

        stackView.addArrangedSubviews {
            selectView.padding(.init(x: 20, y: 0))
            doneButton.padding(.init(x: 20, y: 0))
        }
    }

    func hideBackButton(_ isHidden: Bool = true) {
        backButton.isHidden = isHidden
    }

    @objc private func buttonDoneDidTouch() {
        if let selectedOption = options[safe: selectView.selectedIndex] {
            completion?(selectedOption)
            dismiss(animated: true, completion: nil)
        }
    }

    override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
        super.calculateFittingHeightForPresentedView(targetWidth: targetWidth) +
            containerView.fittingHeight(targetWidth: targetWidth) -
            view.safeAreaInsets.bottom
    }
}
