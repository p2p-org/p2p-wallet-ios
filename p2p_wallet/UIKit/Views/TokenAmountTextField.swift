//
//  TokenAmountTextField.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation
import RxSwift

final class TokenAmountTextField: BEDecimalTextField {
    private var decimals: SolanaSDK.Decimals?

    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        bind()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bind() {
        rx.text
            .map { $0?.cryptoCurrencyFormat }
            .subscribe(onNext: { [weak self] text in
                self?.text = text
            })
            .disposed(by: disposeBag)
        rx.controlEvent(.editingDidEnd)
            .asObservable()
            .subscribe(onNext: { [weak self] in
                self?.text = self?.text?.withoutLastZeros
            })
            .disposed(by: disposeBag)
    }

    func setUp(decimals: SolanaSDK.Decimals?) {
        self.decimals = decimals
        if let currentValue = text?.double?.toLamport(decimals: decimals ?? 9),
           currentValue == 0
        {
            text = nil
            sendActions(for: .editingChanged)
        }
    }

    override func shouldChangeCharactersInRange(_: NSRange, replacementString _: String) -> Bool {
        true
    }
}
