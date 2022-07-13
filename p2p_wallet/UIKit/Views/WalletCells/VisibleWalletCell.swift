//
// Created by Giang Long Tran on 16.02.2022.
//

import BECollectionView
import BEPureLayout
import RxCocoa
import RxSwift
import UIKit

class VisibleWalletCell: BECollectionCell, BECollectionViewCell, UIGestureRecognizerDelegate {
    var onSend: BEVoidCallback?
    var onHide: BEVoidCallback?

    private let baseWalletRef = BERef<BaseWalletCell>()

    override func build() -> UIView {
        BaseWalletCell(
            leadingActions: BECenter { UIImageView(image: .buttonSendSmall, tintColor: .h5887ff) }
                .frame(width: 70)
                .backgroundColor(color: .ebf0fc)
                .onTap(with: gesture { [unowned self] in
                    onSend?()
                    baseWalletRef.view?.swipeableCellRef.view?.centralize()
                }),
            trailingActions: BECenter { UIImageView(image: .eyeHide) }
                .frame(width: 70)
                .onTap(with: gesture { [unowned self] in
                    onHide?()
                    baseWalletRef.view?.swipeableCellRef.view?.centralize()
                })
        ).bind(baseWalletRef)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        baseWalletRef.view?.prepareForReuse()
        onSend = nil
        onHide = nil
    }

    func setUp(with item: AnyHashable?) {
        baseWalletRef.view?.setUp(with: item)
    }

    func showLoading() {
        baseWalletRef.view?.showLoading()
    }

    func hideLoading() {
        baseWalletRef.view?.hideLoading()
    }

    // MARK: - Gesture

    /// Allow leading and trailing action to be recognized during scrolling.
    func gestureRecognizer(
        _ gesture: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith another: UIGestureRecognizer
    ) -> Bool {
        gesture is UIPanGestureRecognizer || another is UIPanGestureRecognizer
    }

    func gesture(_ action: @escaping () -> Void) -> BETapGestureRecognizer {
        let gesture = BETapGestureRecognizer(action)
        gesture.delegate = self
        return gesture
    }
}
