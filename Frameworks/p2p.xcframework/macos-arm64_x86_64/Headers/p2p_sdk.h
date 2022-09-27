#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

char *greet(const char *name);

char *transfer_spl_token(const char *relay_program_id,
                         const char *sender_token_account_address,
                         const char *recipient_address,
                         const char *token_mint_address,
                         const char *authority_address,
                         uint64_t amount,
                         uint8_t decimals,
                         uint64_t fee_amount,
                         const char *blockhash,
                         uint64_t minimum_token_account_balance,
                         bool needs_create_recipient_token_account,
                         const char *fee_payer_address);

char *top_up(const char *relay_program_id,
             const char *user_source_token_account_address,
             const char *source_token_mint_address,
             const char *authority_address,
             const char *swap_data,
             uint64_t fee_amount,
             const char *blockhash,
             uint64_t minimum_relay_account_balance,
             uint64_t minimum_token_account_balance,
             bool needs_create_user_relay_account,
             const char *fee_payer_address);

char *sign_transaction(const char *transaction, const char *keypair, const char *blockhash);

/**
 * C-interface for calling [p2p_sdk::api::nonblocking::get_solend_collateral_accounts]
 */
char *get_solend_collateral_accounts(const char *rpc_url, const char *owner);

/**
 * C-interface for calling [p2p_sdk::api::nonblocking::get_solend_market_info]
 */
char *get_solend_market_info(const char *tokens, const char *pool);

/**
 * C-interface for calling [p2p_sdk::api::nonblocking::get_solend_user_deposits]
 */
char *get_solend_user_deposits(const char *owner, const char *pool);

/**
 * C-interface for calling [p2p_sdk::api::nonblocking::get_solend_user_deposit_by_symbol]
 */
char *get_solend_user_deposit_by_symbol(const char *owner, const char *symbol, const char *pool);

/**
 * C-interface for [p2p_sdk::api::get_solend_deposit_fees]
 */
char *get_solend_deposit_fees(const char *rpc_url,
                              const char *owner,
                              uint64_t token_amount,
                              const char *token_symbol);

/**
 * IOS native FFI API for calling [p2p_sdk::api::nonblocking::create_solend_deposit_transactions]
 */
char *create_solend_deposit_transactions(const char *solana_rpc_url,
                                         const char *relay_program_id,
                                         uint64_t amount,
                                         const char *symbol,
                                         const char *owner_address,
                                         const char *environment,
                                         const char *lendng_market_address,
                                         const char *blockhash,
                                         uint32_t free_transactions_count,
                                         bool need_to_use_relay,
                                         const char *pay_fee_in_token,
                                         const char *fee_payer_address);

/**
 * IOS native FFI API for calling [p2p_sdk::api::nonblocking::create_solend_withdraw_transactions]
 */
char *create_solend_withdraw_transactions(const char *solana_rpc_url,
                                          const char *relay_program_id,
                                          uint64_t amount,
                                          const char *symbol,
                                          const char *owner_address,
                                          const char *environment,
                                          const char *lendng_market_address,
                                          const char *blockhash,
                                          uint32_t free_transactions_count,
                                          bool need_to_use_relay,
                                          const char *pay_fee_in_token,
                                          const char *fee_payer_address);

/**
 * C-interface for [p2p_sdk::api::nonblocking::get_solend_config]
 */
char *get_solend_config(const char *environment);
