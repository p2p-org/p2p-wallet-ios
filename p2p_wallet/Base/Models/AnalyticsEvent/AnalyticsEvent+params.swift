//
//  AnalyticsEvent+params.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/06/2021.
//

import Foundation

extension AnalyticsEvent {
    var params: [AnyHashable: Any]? {
        switch self {
        // first_in
        case .firstInOpen: return nil
        case .firstInCreateWalletClick: return nil
        case .firstInIHaveWalletClick: return nil
        // create_wallet
        case .createWalletOpen: return nil
        case .createWalletCopySeedClick: return nil
        case .createWalletIHaveSavedWordsClick: return nil
        case .createWalletBackupToIcloudClick: return nil
        case .createWalletNextClick: return nil
        // setup
        case .setupOpen(let fromPage): return ["fromPage": fromPage]
        case .setupPinKeydown1: return nil
        case .setupPinKeydown2: return nil
        case .setupFaceidOpen: return nil
        case .setupFaceidClick(let faceID): return ["faceID": faceID]
        case .setupAllowPushOpen: return nil
        case .setupAllowPushSelected(let push): return ["push": push]
        case .setupFinishOpen: return nil
        case .setupFinishClick: return nil
        case .setupWelcomeBackOpen: return nil
        // recovery
        case .recoveryOpen(let fromPage): return ["fromPage": fromPage]
        case .recoveryRestoreManualyClick: return nil
        case .recoveryRestoreIcloudClick: return nil
        case .recoveryEnterSeedOpen: return nil
        case .recoveryEnterSeedKeydown: return nil
        case .recoveryEnterSeedPaste: return nil
        case .recoveryDoneClick: return nil
        case .recoveryDerivableAccountsOpen: return nil
        case .recoveryDerivableAccountsPathSelected(let path): return ["path": path]
        case .recoveryRestoreClick: return nil

        // main_screen
        case .mainScreenWalletsOpen: return nil
        case .mainScreenBuyOpen: return nil
        case .mainScreenReceiveOpen: return nil
        case .mainScreenSendOpen: return nil
        case .mainScreenSwapOpen: return nil
        case .mainScreenQrOpen: return nil
        case .mainScreenSettingsOpen: return nil
        case .mainScreenTokenDetailsOpen(let tokenTicker): return ["tokenTicker": tokenTicker]
        // token_details
        case .tokenDetailsOpen(let tokenTicker): return ["tokenTicker": tokenTicker]
        case .tokenDetailQrClick: return nil
        case .tokenDetailsBuyClick: return nil
        case .tokenDetailsReceiveClick: return nil
        case .tokenDetailsSendClick: return nil
        case .tokenDetailsSwapClick: return nil
        case .tokenDetailsAddressCopy: return nil
        case .tokenDetailsActivityScroll(let pageNum): return ["pageNum": pageNum]
        case .tokenDetailsDetailsOpen: return nil
        // receive
        case .receiveOpen(let fromPage): return ["fromPage": fromPage]
        case .receiveAddressCopy: return nil
        case .receiveAddressShare: return nil
        case .receiveViewExplorerOpen: return nil
        // send
        case .sendOpen(let fromPage): return ["fromPage": fromPage]
        case .sendSelectTokenClick(let tokenTicker): return ["tokenTicker": tokenTicker]
        case .sendChangeInputMode(let selectedValue): return ["selectedValue": selectedValue]
        case .sendAmountKeydown(let sum): return ["sum": sum]
        case .sendAvailableClick(let sum): return ["sum": sum]
        case .sendAddressKeydown: return nil
        case .sendScanQrClick: return nil
        case .sendSendClick(let tokenTicker, let sum): return ["tokenTicker": tokenTicker, "sum": sum]
        case .sendDoneClick(let txStatus): return ["txStatus": txStatus]
        case .sendExplorerClick(let txStatus): return ["txStatus": txStatus]
        case .sendTryAgainClick(let error): return ["error": error]
        case .sendCancelClick(let error): return ["error": error]
        // swap
        case .swapOpen(let fromPage): return ["fromPage": fromPage]
        case .swapTokenASelectClick(let tokenTicker): return ["tokenTicker": tokenTicker]
        case .swapTokenBSelectClick(let tokenTicker): return ["tokenTicker": tokenTicker]
        case .swapTokenAAmountKeydown(let sum): return ["sum": sum]
        case .swapTokenBAmountKeydown(let sum): return ["sum": sum]
        case .swapAvailableClick(let sum): return ["sum": sum]
        case .swapReverseClick: return nil
        case .swapSlippageClick: return nil
        case .swapSlippageKeydown(let slippage): return ["slippage": slippage]
        case .swapSwapClick(let tokenA, let tokenB, let sumA, let sumB): return ["tokenA": tokenA, "tokenB": tokenB, "sumA": sumA, "sumB": sumB]
        case .swapDoneClick(let txStatus): return ["txStatus": txStatus]
        case .swapExplorerClick(let txStatus): return ["txStatus": txStatus]
        case .swapTryAgainClick(let error): return ["error": error]
        case .swapCancelClick(let error): return ["error": error]
        // scan_qr
        case .scanQrOpen(let fromPage): return ["fromPage": fromPage]
        case .scanQrSuccess: return nil
        case .scanQrClose: return nil
        // settings
        case .settingsOpen(let fromPage): return ["fromPage": fromPage]
        case .settingsNetworkSelected(let network): return ["network": network]
        case .settingsHideBalancesClick(let hide): return ["hide": hide]
        case .settingBackupOpen: return nil
        case .settingsSecuritySelected(let faceID): return ["faceID": faceID]
        case .settingsLanguageSelected(let language): return ["language": language]
        case .settingsAppearanceSelected(let appearance): return ["appearance": appearance]
        case .settingsСurrencySelected(let сurrency): return ["сurrency": сurrency]
        case .settingsLogoutClick: return nil
        }
    }
}
