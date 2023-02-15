//
//  TokenAmountTextField.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation
import RxSwift
import SolanaSwift

final class TokenAmountTextField: BEDecimalTextField {
    private var decimals: Decimals?

    var value: Double {
        text.map { $0.double ?? 0 } ?? 0
    }

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
            .filter { !($0?.isEmpty ?? false) && $0 != "0" }
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
      rx.controlEvent(.editingDidBegin)
          .asObservable()
          .subscribe(onNext: { [unowned self] in
              DispatchQueue.main.async {
                  let endPosition = self.endOfDocument
                  self.selectedTextRange = self.textRange(from: endPosition, to: endPosition)
              }
          })
          .disposed(by: disposeBag)
    }

    func setUp(decimals: Decimals?) {
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
