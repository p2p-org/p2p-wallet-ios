//
//  TokenAmountTextField.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Combine
import Foundation
import SolanaSwift

final class TokenAmountTextField: BEDecimalTextField {
    private var decimals: Decimals?

    var value: Double {
        text.map { $0.double ?? 0 } ?? 0
    }

    private var subscriptions = [AnyCancellable]()

    override init(frame: CGRect) {
        super.init(frame: frame)
        bind()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bind() {
        textPublisher
            .map { $0?.cryptoCurrencyFormat }
            .sink { [weak self] text in
                self?.text = text
            }
            .store(in: &subscriptions)

        NotificationCenter.default
            .publisher(for: UITextField.textDidEndEditingNotification, object: self)
            .sink { [weak self] _ in
                self?.text = self?.text?.withoutLastZeros
            }
            .store(in: &subscriptions)
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
