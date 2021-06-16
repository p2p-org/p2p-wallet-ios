//
//  AnalyticsEvent.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/06/2021.
//

import Foundation

enum AnalyticsEvent: String {
    // landing
    case landingIHaveWalletClick = "landing_i_have_wallet_click"
    case landingCreateWalletClick = "landing_create_wallet_click"
    case landingGoToWebWallet1Click = "landing_go_to_web_wallet_1_click"
    case landingGoToWebWallet2Click = "landing_go_to_web_wallet_2_click"
    case landingGoToWebWallet3Click = "landing_go_to_web_wallet_3_click"
    case landingDownloadForIos1Click = "landing_download_for_ios_1_click"
    case landingDownloadForIos2Click = "landing_download_for_ios_2_click"
    case landingDownloadForIos3Click = "landing_download_for_ios_3_click"
    case landingDownloadForIos4Click = "landing_download_for_ios_4_click"
    
    // sign up
    case signupOpen = "signup_open"
    case signupIHaveSavedWordsClick = "signup_i_have_saved_words_click"
    case signupContinueMnemonicClick = "signup_continue_mnemonic_click"
    case signupPasteSeedOpen = "signup_paste_seed_open"
    case signupSeedPasted = "signup_seed_pasted"
    case signupContinuePasteClick = "signup_continue_paste_click"
    case signupCreatePasswordOpen = "signup_create_password_open"
    case signupPasswordKeydown = "signup_password_keydown"
    case signupPasswordConfirmKeydown = "signup_password_confirm_keydown"
    case signupContinueCreatePasswordClick = "signup_continue_create_password_click"
    case signupWalletReadyOpen = "signup_wallet_ready_open"
    case signupFinishSetupClick = "signup_finish_setup_click"
    
    // login
    case loginOpen = "login_open"
    case loginSolletioClick = "login_solletio_click"
    case loginSolletExtensionClick = "login_sollet_extension_click"
    case loginPhantomClick = "login_phantom_click"
    case loginSeedKeydown = "login_seed_keydown"
    case loginCreatePasswordOpen = "login_create_password_open"
    case loginPasswordKeydown = "login_password_keydown"
    case loginPasswordConfirmKeydown = "login_password_confirm_keydown"
    case loginContinueCreatePasswordClick = "login_continue_create_password_click"
    case loginSelectDerivationPathClick = "login_select_derivation_path_click"
    case loginContinueDerivationPathClick = "login_continue_derivation_path_click"
    case loginWalletReadyOpen = "login_wallet_ready_open"
    case loginFinishSetupClick = "login_finish_setup_click"
    
    // restore
    case restoreWelcomeBackOpen = "restore_welcome_back_open"
    case restorePasswordKeydown = "restore_password_keydown"
    case restoreAccessWalletClick = "restore_access_wallet_click"
    case restoreAccessViaSeedClick = "restore_access_via_seed_click"
    
    // wallets
    case walletsOpen = "wallets_open"
    
    // wallet
    case walletOpen = "wallet_open"
    case walletQrClick = "wallet_qr_click"
    case walletSolAddressCopy = "wallet_sol_address_copy"
    case walletTokenAddressCopy = "wallet_token_address_copy"
    case walletMintAddressCopy = "wallet_mint_address_copy"
    case walletSendClick = "wallet_send_click"
    case walletSwapClick = "wallet_swap_click"
    case walletActivityScroll = "wallet_activity_scroll"
    case walletTransactionDetailsOpen = "wallet_transaction_details_open"
    
    // receive
    case receiveOpen = "receive_open"
    case receiveAddressCopy = "receive_address_copy"
    
    // send
    case sendOpen = "send_open"
    case sendSelectTokenClick = "send_select_token_click"
    case sendAmountKeydown = "send_amount_keydown"
    case sendAvailableClick = "send_available_click"
    case sendAddressKeydown = "send_address_keydown"
    case sendSendClick = "send_send_click"
    case sendCloseClick = "send_close_click"
    case sendDoneClick = "send_done_click"
    case sendExplorerClick = "send_explorer_click"
    case sendTryAgainClick = "send_try_again_click"
    case sendCancelClick = "send_cancel_click"
    
    // swap
    case swapOpen = "swap_open"
    case swapTokenASelectClick = "swap_token_a_select_click"
    case swapTokenBSelectClick = "swap_token_b_select_click"
    case swapTokenAAmountKeydown = "swap_token_a_amount_keydown"
    case swapTokenBAmountKeydown = "swap_token_b_amount_keydown"
    case swapAvailableClick = "swap_available_click"
    case swapReverseClick = "swap_reverse_click"
    case swapSlippageClick = "swap_slippage_click"
    case swapSlippageDoneClick = "swap_slippage_done_click"
    case swapSwapClick = "swap_swap_click"
    case swapCloseClick = "swap_close_click"
    case swapDoneClick = "swap_done_click"
    case swapExplorerClick = "swap_explorer_click"
    case swapTryAgainClick = "swap_try_again_click"
    case swapCancelClick = "swap_cancel_click"
    
    // settings
    case settingsOpen = "settings_open"
    case settingsNetworkClick = "settings_network_click"
    case settingsHideZeroBalancesClick = "settings_hide_zero_balances_click"
    case settingsLogoutClick = "settings_logout_click"
}
