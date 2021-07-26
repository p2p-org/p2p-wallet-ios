//
//  LocalizationTests.swift
//  p2p_walletTests
//
//  Created by Chung Tran on 26/07/2021.
//

import XCTest
@testable import p2p_wallet

class LocalizationTests: XCTestCase {
    func testRussianLocalization() throws {
        // change current bundle
        UIApplication.changeLanguage(to: .init(code: "ru"))
        
        // wrong pincode
        XCTAssertEqual(L10n.wrongPinCodeDAttemptSLeft(0), "Неверный PIN-код, осталось 0 попыток")
        XCTAssertEqual(L10n.wrongPinCodeDAttemptSLeft(1), "Неверный PIN-код, осталась 1 попытка")
        XCTAssertEqual(L10n.wrongPinCodeDAttemptSLeft(2), "Неверный PIN-код, осталось 2 попытки")
        XCTAssertEqual(L10n.wrongPinCodeDAttemptSLeft(3), "Неверный PIN-код, осталось 3 попытки")
        XCTAssertEqual(L10n.wrongPinCodeDAttemptSLeft(4), "Неверный PIN-код, осталось 4 попытки")
        XCTAssertEqual(L10n.wrongPinCodeDAttemptSLeft(7), "Неверный PIN-код, осталось 7 попыток")
        
        // hidden wallets
        XCTAssertEqual(L10n.dHiddenWallet(0), "0 скрытых кошельков")
        XCTAssertEqual(L10n.dHiddenWallet(1), "1 скрытый кошелек")
        XCTAssertEqual(L10n.dHiddenWallet(2), "2 скрытых кошелька")
        XCTAssertEqual(L10n.dHiddenWallet(3), "3 скрытых кошелька")
        XCTAssertEqual(L10n.dHiddenWallet(4), "4 скрытых кошелька")
        XCTAssertEqual(L10n.dHiddenWallet(5), "5 скрытых кошельков")
        XCTAssertEqual(L10n.dHiddenWallet(7), "7 скрытых кошельков")
        XCTAssertEqual(L10n.dHiddenWallet(21), "21 скрытый кошелек")
        XCTAssertEqual(L10n.dHiddenWallet(22), "22 скрытых кошелька")
        XCTAssertEqual(L10n.dHiddenWallet(23), "23 скрытых кошелька")
        XCTAssertEqual(L10n.dHiddenWallet(24), "24 скрытых кошелька")
        XCTAssertEqual(L10n.dHiddenWallet(25), "25 скрытых кошельков")
        XCTAssertEqual(L10n.dHiddenWallet(27), "27 скрытых кошельков")
        
        // day ago
        XCTAssertEqual(L10n.dDayAgo(0), "0 дней назад")
        XCTAssertEqual(L10n.dDayAgo(1), "1 день назад")
        XCTAssertEqual(L10n.dDayAgo(2), "2 дня назад")
        XCTAssertEqual(L10n.dDayAgo(3), "3 дня назад")
        XCTAssertEqual(L10n.dDayAgo(4), "4 дня назад")
        XCTAssertEqual(L10n.dDayAgo(5), "5 дней назад")
        XCTAssertEqual(L10n.dDayAgo(7), "7 дней назад")
        XCTAssertEqual(L10n.dDayAgo(21), "21 день назад")
        XCTAssertEqual(L10n.dDayAgo(22), "22 дня назад")
        XCTAssertEqual(L10n.dDayAgo(23), "23 дня назад")
        XCTAssertEqual(L10n.dDayAgo(24), "24 дня назад")
        XCTAssertEqual(L10n.dDayAgo(25), "25 дней назад")
        XCTAssertEqual(L10n.dDayAgo(27), "27 дней назад")
    }
}
