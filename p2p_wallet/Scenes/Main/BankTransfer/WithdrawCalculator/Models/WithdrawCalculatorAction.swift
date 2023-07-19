struct WithdrawCalculatorAction {
    let isEnabled: Bool
    let title: String

    static let zero = WithdrawCalculatorAction(isEnabled: false, title: L10n.enterAmount)
    static let failure = WithdrawCalculatorAction(isEnabled: false, title: L10n.canTWithdrawNow)
}
