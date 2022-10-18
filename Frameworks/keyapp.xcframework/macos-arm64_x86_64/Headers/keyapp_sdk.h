#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct Runtime {

} Runtime;

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
 * C-interface for calling [keyapp_sdk::api::nonblocking::get_solend_collateral_accounts]
 *
 * # iOS
 * For iOS team added another extra argument [tokio::runtime::Runtime] it can be created by
 * [keyapp_sdk::runtime::spawn_runtime] and dropped by [keyapp_sdk::runtime::drop_runtime]
 * Other arguments described in [keyapp_sdk::api::nonblocking::get_solend_collateral_accounts]
 */
char *get_solend_collateral_accounts(struct Runtime *const *runtime,
                                     const char *rpc_url,
                                     const char *owner);

/**
 * C-interface for calling [keyapp_sdk::api::nonblocking::get_solend_market_info]
 *
 * # iOS
 * For iOS team added another extra argument [tokio::runtime::Runtime] it can be created by
 * [keyapp_sdk::runtime::spawn_runtime] and dropped by [keyapp_sdk::runtime::drop_runtime]
 * Other arguments described in [keyapp_sdk::api::nonblocking::get_solend_collateral_accounts]
 */
char *get_solend_market_info(struct Runtime *const *runtime, const char *tokens, const char *pool);

/**
 * C-interface for calling [keyapp_sdk::api::nonblocking::get_solend_user_deposits]
 *
 * # iOS
 * For iOS team added another extra argument [tokio::runtime::Runtime] it can be created by
 * [keyapp_sdk::runtime::spawn_runtime] and dropped by [keyapp_sdk::runtime::drop_runtime]
 * Other arguments described in [keyapp_sdk::api::nonblocking::get_solend_collateral_accounts]
 */
char *get_solend_user_deposits(struct Runtime *const *runtime, const char *owner, const char *pool);

/**
 * C-interface for calling [keyapp_sdk::api::nonblocking::get_solend_user_deposit_by_symbol]
 *
 * # iOS
 * For iOS team added another extra argument [tokio::runtime::Runtime] it can be created by
 * [keyapp_sdk::runtime::spawn_runtime] and dropped by [keyapp_sdk::runtime::drop_runtime]
 * Other arguments described in [keyapp_sdk::api::nonblocking::get_solend_collateral_accounts]
 */
char *get_solend_user_deposit_by_symbol(struct Runtime *const *runtime,
                                        const char *owner,
                                        const char *symbol,
                                        const char *pool);

/**
 * C-interface for [keyapp_sdk::api::get_solend_deposit_fees]
 *
 * # iOS
 * For iOS team added another extra argument [tokio::runtime::Runtime] it can be created by
 * [keyapp_sdk::runtime::spawn_runtime] and dropped by [keyapp_sdk::runtime::drop_runtime]
 * Other arguments described in [keyapp_sdk::api::nonblocking::get_solend_collateral_accounts]
 */
char *get_solend_deposit_fees(struct Runtime *const *runtime,
                              const char *rpc_url,
                              const char *owner,
                              uint64_t token_amount,
                              const char *token_symbol);

/**
 * IOS native FFI API for calling [keyapp_sdk::api::nonblocking::create_solend_deposit_transactions]
 *
 * # iOS
 * For iOS team added another extra argument [tokio::runtime::Runtime] it can be created by
 * [keyapp_sdk::runtime::spawn_runtime] and dropped by [keyapp_sdk::runtime::drop_runtime]
 * Other arguments described in [keyapp_sdk::api::nonblocking::get_solend_collateral_accounts]
 */
char *create_solend_deposit_transactions(struct Runtime *const *runtime,
                                         const char *solana_rpc_url,
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
 * IOS native FFI API for calling [keyapp_sdk::api::nonblocking::create_solend_withdraw_transactions]
 *
 * # iOS
 * For iOS team added another extra argument [tokio::runtime::Runtime] it can be created by
 * [keyapp_sdk::runtime::spawn_runtime] and dropped by [keyapp_sdk::runtime::drop_runtime]
 * Other arguments described in [keyapp_sdk::api::nonblocking::get_solend_collateral_accounts]
 */
char *create_solend_withdraw_transactions(struct Runtime *const *runtime,
                                          const char *solana_rpc_url,
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
 * C-interface for [keyapp_sdk::api::nonblocking::get_solend_config]
 *
 * # iOS
 * For iOS team added another extra argument [tokio::runtime::Runtime] it can be created by
 * [keyapp_sdk::runtime::spawn_runtime] and dropped by [keyapp_sdk::runtime::drop_runtime]
 * Other arguments described in [keyapp_sdk::api::nonblocking::get_solend_collateral_accounts]
 */
char *get_solend_config(struct Runtime *const *runtime, const char *environment);

/**
 * C-interface for [keyapp_sdk::runtime::spawn_runtime]
 */
struct Runtime *spawn_runtime(uintptr_t worker_threads, uintptr_t max_blocking_threads);

/**
 * C-interface for [keyapp_sdk::runtime::drop_runtime]
 */
void drop_runtime(struct Runtime *runtime);
