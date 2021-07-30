//
//  AnalyticsEvent+RawRepresentable.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/06/2021.
//

import Foundation

extension AnalyticsEvent {
    var eventName: String {
        switch self {
        // first_in
        case .firstInOpen: return "first_in_open"
        case .firstInCreateWalletClick: return "first_in_create_wallet_click"
        case .firstInIHaveWalletClick: return "first_in_i_have_wallet_click"
        // create_wallet
        case .createWalletOpen: return "create_wallet_open"
        case .createWalletCopySeedClick: return "create_wallet_copy_seed_click"
        case .createWalletIHaveSavedWordsClick: return "create_wallet_i_have_saved_words_click"
        case .createWalletBackupToIcloudClick: return "create_wallet_backup_to_icloud_click"
        case .createWalletNextClick: return "create_wallet_next_click"
        // setup
        case .setupOpen: return "setup_open"
        case .setupPinKeydown1: return "setup_pin_keydown_1"
        case .setupPinKeydown2: return "setup_pin_keydown_2"
        case .setupFaceidOpen: return "setup_faceid_open"
        case .setupFaceidClick: return "setup_faceid_click"
        case .setupAllowPushOpen: return "setup_allow_push_open"
        case .setupAllowPushSelected: return "setup_allow_push_selected"
        case .setupFinishOpen: return "setup_finish_open"
        case .setupFinishClick: return "setup_finish_click"
        case .setupWelcomeBackOpen: return "setup_welcome_back_open"
        // recovery
        case .recoveryOpen: return "recovery_open"
        case .recoveryRestoreManualyClick: return "recovery_restore_manualy_click"
        case .recoveryRestoreIcloudClick: return "recovery_restore_icloud_click"
        case .recoveryEnterSeedOpen: return "recovery_enter_seed_open"
        case .recoveryEnterSeedKeydown: return "recovery_enter_seed_keydown"
        case .recoveryEnterSeedPaste: return "recovery_enter_seed_paste"
        case .recoveryDoneClick: return "recovery_done_click"
        case .recoveryDerivableAccountsOpen: return "recovery_derivable_accounts_open"
        case .recoveryDerivableAccountsPathSelected: return "recovery_derivable_accounts_path_selected"
        case .recoveryRestoreClick: return "recovery_restore_click"

        // main_screen
        case .mainScreenWalletsOpen: return "main_screen_wallets_open"
        case .mainScreenBuyOpen: return "main_screen_buy_open"
        case .mainScreenReceiveOpen: return "main_screen_receive_open"
        case .mainScreenSendOpen: return "main_screen_send_open"
        case .mainScreenSwapOpen: return "main_screen_swap_open"
        case .mainScreenQrOpen: return "main_screen_qr_open"
        case .mainScreenSettingsOpen: return "main_screen_settings_open"
        case .mainScreenTokenDetailsOpen: return "main_screen_token_details_open"
        // token_details
        case .tokenDetailsOpen: return "token_details_open"
        case .tokenDetailQrClick: return "token_detail_qr_click"
        case .tokenDetailsBuyClick: return "token_details_buy_click"
        case .tokenDetailsReceiveClick: return "token_details_receive_click"
        case .tokenDetailsSendClick: return "token_details_send_click"
        case .tokenDetailsSwapClick: return "token_details_swap_click"
        case .tokenDetailsAddressCopy: return "token_details_address_copy"
        case .tokenDetailsActivityScroll: return "token_details_activity_scroll"
        case .tokenDetailsDetailsOpen: return "token_details_details_open"
        // receive
        case .receiveOpen: return "receive_open"
        case .receiveAddressCopy: return "receive_address_copy"
        case .receiveAddressShare: return "receive_address_share"
        case .receiveViewExplorerOpen: return "receive_view_explorer_open"
        // send
        case .sendOpen: return "send_open"
        case .sendSelectTokenClick: return "send_select_token_click"
        case .sendChangeInputMode: return "send_change_input_mode"
        case .sendAmountKeydown: return "send_amount_keydown"
        case .sendAvailableClick: return "send_available_click"
        case .sendAddressKeydown: return "send_address_keydown"
        case .sendScanQrClick: return "send_scan_qr_click"
        case .sendSendClick: return "send_send_click"
        case .sendDoneClick: return "send_done_click"
        case .sendExplorerClick: return "send_explorer_click"
        case .sendTryAgainClick: return "send_try_again_click"
        case .sendCancelClick: return "send_cancel_click"
        // swap
        case .swapOpen: return "swap_open"
        case .swapTokenASelectClick: return "swap_token_a_select_click"
        case .swapTokenBSelectClick: return "swap_token_b_select_click"
        case .swapTokenAAmountKeydown: return "swap_token_a_amount_keydown"
        case .swapTokenBAmountKeydown: return "swap_token_a_amount_keydown"
        case .swapAvailableClick: return "swap_available_click"
        case .swapReverseClick: return "swap_reverse_click"
        case .swapSlippageClick: return "swap_slippage_click"
        case .swapSlippageKeydown: return "swap_slippage_keydown"
        case .swapSwapClick: return "swap_swap_click"
        case .swapDoneClick: return "swap_done_click"
        case .swapExplorerClick: return "swap_explorer_click"
        case .swapTryAgainClick: return "swap_try_again_click"
        case .swapCancelClick: return "swap_cancel_click"
        // scan_qr
        case .scanQrOpen: return "scan_qr_open"
        case .scanQrSuccess: return "scan_qr_success"
        case .scanQrClose: return "scan_qr_close"
        // settings
        case .settingsOpen: return "settings_open"
        case .settingsNetworkSelected: return "settings_network_selected"
        case .settingsHideBalancesClick: return "settings_hide_balances_click"
        case .settingBackupOpen: return "setting_backup_open"
        case .settingsSecuritySelected: return "settings_security_selected"
        case .settingsLanguageSelected: return "settings_language_selected"
        case .settingsAppearanceSelected: return "settings_appearance_selected"
        case .settingsСurrencySelected: return "settings_сurrency_selected"
        case .settingsLogoutClick: return "settings_logout_click"
        }
    }
}
