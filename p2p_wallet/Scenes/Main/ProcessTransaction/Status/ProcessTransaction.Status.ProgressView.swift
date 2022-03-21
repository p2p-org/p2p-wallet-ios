//
//  PT.ProgressView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2022.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

extension ProcessTransaction.Status {
    final class ProgressView: UIView {
        private let disposeBag = DisposeBag()
        fileprivate let determinedProgressView = UIProgressView(height: 2)
        private let indeterminedProgressView = IndetermineView(height: 2)

        fileprivate var isIndetermine: Bool = true {
            didSet {
                determinedProgressView.isHidden = isIndetermine
                indeterminedProgressView.isHidden = !isIndetermine
            }
        }

        init() {
            super.init(frame: .zero)
            configureForAutoLayout()
            autoSetDimension(.height, toSize: 2)

            addSubview(determinedProgressView)
            determinedProgressView.autoPinEdgesToSuperviewEdges()

            addSubview(indeterminedProgressView)
            indeterminedProgressView.tintColor = .h5887ff
            indeterminedProgressView.autoPinEdgesToSuperviewEdges()

            isIndetermine = true
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private final class IndetermineView: BEView {
        private let indicatorLayer = CALayer()
        private let indicatorWidth: CGFloat = 100

        override var tintColor: UIColor! {
            didSet { indicatorLayer.backgroundColor = tintColor.cgColor }
        }

        override func commonInit() {
            super.commonInit()
            layer.addSublayer(indicatorLayer)
            configureForAutoLayout()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if indicatorLayer.animation(forKey: "x") == nil {
                startAnimating()
            }
        }

        func startAnimating() {
            let progressRect = CGRect(
                origin: .init(x: 0 - indicatorWidth, y: 0),
                size: .init(
                    width: indicatorWidth,
                    height: bounds.height
                )
            )

            indicatorLayer.frame = progressRect

            let animation = CABasicAnimation(keyPath: "position.x")
            animation.fromValue = 0 - indicatorWidth
            animation.toValue = bounds.width + indicatorWidth
            animation.repeatCount = .infinity
            animation.duration = 3
            indicatorLayer.add(animation, forKey: "x")
        }
    }
}

extension Reactive where Base == ProcessTransaction.Status.ProgressView {
    var transactionStatus: Binder<PendingTransaction.TransactionStatus> {
        Binder(base) { view, status in
            var isIndetermine = false

            var progressTintColor = UIColor.h5887ff

            switch status {
            case .sending:
                isIndetermine = true
            case .error:
                progressTintColor = .alert
            default:
                break
            }

            view.isIndetermine = isIndetermine
            view.determinedProgressView.progressTintColor = progressTintColor
            view.determinedProgressView.progress = status.progress
        }
    }
}
