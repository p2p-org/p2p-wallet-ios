//
//  AnalyticsEvent.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/06/2021.
//

import Foundation

protocol AnalyticsEventType: RawRepresentable where RawValue == String {}

enum AnalyticsEvent {
    enum Landing: String, AnalyticsEventType {
        case iHaveWalletClick = "landing_i_have_wallet_click"
        case createWalletClick = "landing_create_wallet_click"
        case goToWebWallet1Click = "landing_go_to_web_wallet_1_click"
        case goToWebWallet2Click = "landing_go_to_web_wallet_2_click"
        case goToWebWallet3Click = "landing_go_to_web_wallet_3_click"
        case downloadForIos1Click = "landing_download_for_ios_1_click"
        case downloadForIos2Click = "landing_download_for_ios_2_click"
        case downloadForIos3Click = "landing_download_for_ios_3_click"
        case downloadForIos4Click = "landing_download_for_ios_4_click"
    }
    
    enum SignUp: String, AnalyticsEventType {
        case open = "signup_open"
        case iHaveSavedWordsClick = "signup_i_have_saved_words_click"
        case continueMnemonicClick = "signup_continue_mnemonic_click"
        case pasteSeedOpen = "signup_paste_seed_open"
        case seedPasted = "signup_seed_pasted"
        case continuePasteClick = "signup_continue_paste_click"
        case createPasswordOpen = "signup_create_password_open"
        case passwordKeydown = "signup_password_keydown"
        case passwordConfirmKeydown = "signup_password_confirm_keydown"
        case continueCreatePasswordClick = "signup_continue_create_password_click"
        case walletReadyOpen = "signup_wallet_ready_open"
        case finishSetupClick = "signup_finish_setup_click"
    }
    
    enum Login: String, AnalyticsEventType {
        case open = "login_open"
        case solletioClick = "login_solletio_click"
        case solletExtensionClick = "login_sollet_extension_click"
        case phantomClick = "login_phantom_click"
        case seedKeydown = "login_seed_keydown"
        case createPasswordOpen = "login_create_password_open"
        case passwordKeydown = "login_password_keydown"
        case passwordConfirmKeydown = "login_password_confirm_keydown"
        case continueCreatePasswordClick = "login_continue_create_password_click"
        case selectDerivationPathClick = "login_select_derivation_path_click"
        case continueDerivationPathClick = "login_continue_derivation_path_click"
        case walletReadyOpen = "login_wallet_ready_open"
        case finishSetupClick = "login_finish_setup_click"
    }
    
    enum Restore: String, AnalyticsEventType {
        case welcomeBackOpen = "restore_welcome_back_open"
        case passwordKeydown = "restore_password_keydown"
        case accessWalletClick = "restore_access_wallet_click"
        case accessViaSeedClick = "restore_access_via_seed_click"
    }
    
    enum Wallets: String, AnalyticsEventType {
        case open = "wallets_open"
    }
    
    enum Wallet: String, AnalyticsEventType {
        case open = "wallet_open"
        case qrClick = "wallet_qr_click"
        case solAddressCopy = "wallet_sol_address_copy"
        case tokenAddressCopy = "wallet_token_address_copy"
        case mintAddressCopy = "wallet_mint_address_copy"
        case sendClick = "wallet_send_click"
        case swapClick = "wallet_swap_click"
        case activityScroll = "wallet_activity_scroll"
        case transactionDetailsOpen = "wallet_transaction_details_open"
    }
    
    enum Receive: String, AnalyticsEventType {
        case open = "receive_open"
        case addressCopy = "receive_address_copy"
    }
    
    enum Send: String, AnalyticsEventType {
        case open = "send_open"
        case selectTokenClick = "send_select_token_click"
        case amountKeydown = "send_amount_keydown"
        case availableClick = "send_available_click"
        case addressKeydown = "send_address_keydown"
        case sendClick = "send_send_click"
        case closeClick = "send_close_click"
        case doneClick = "send_done_click"
        case explorerClick = "send_explorer_click"
        case tryAgainClick = "send_try_again_click"
        case cancelClick = "send_cancel_click"
    }
    
    enum Swap: String, AnalyticsEventType {
        case open = "swap_open"
        case tokenASelectClick = "swap_token_a_select_click"
        case tokenBSelectClick = "swap_token_b_select_click"
        case tokenAAmountKeydown = "swap_token_a_amount_keydown"
        case tokenBAmountKeydown = "swap_token_b_amount_keydown"
        case availableClick = "swap_available_click"
        case reverseClick = "swap_reverse_click"
        case slippageClick = "swap_slippage_click"
        case slippageDoneClick = "swap_slippage_done_click"
        case swapClick = "swap_swap_click"
        case closeClick = "swap_close_click"
        case doneClick = "swap_done_click"
        case explorerClick = "swap_explorer_click"
        case tryAgainClick = "swap_try_again_click"
        case cancelClick = "swap_cancel_click"
    }
    
    enum Settings: String, AnalyticsEventType {
        case open = "settings_open"
        case networkClick = "settings_network_click"
        case hideZeroBalancesClick = "settings_hide_zero_balances_click"
        case logoutClick = "settings_logout_click"
    }
}
