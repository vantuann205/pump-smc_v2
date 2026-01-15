// ============================================================================
// TOKEN MINT VALIDATOR - Mint token trực tiếp vào Pool
// ============================================================================
// Validator này đảm bảo token được mint một lần duy nhất và gửi thẳng vào pool
// Pool address là CỐ ĐỊNH (từ pool_spend.ak không có parameters)

use aiken/collection/dict
use aiken/collection/list
use cardano/address.{Address, Script}
use cardano/assets.{PolicyId, quantity_of, tokens}
use cardano/transaction.{InlineDatum, Input, Output, OutputReference, Transaction}

// ----------------------------------------------------------------------------
// DATUM: Dữ liệu pool (phải khớp với pool_spend.ak)
// ----------------------------------------------------------------------------
pub type PoolDatum {
  token_policy: PolicyId,
  token_name: ByteArray,
  slope: Int,
  current_supply: Int,
  creator: ByteArray,
}

// ----------------------------------------------------------------------------
// REDEEMER: Hành động mint
// ----------------------------------------------------------------------------
pub type MintAction {
  MintToPool
}

// ============================================================================
// VALIDATOR: Mint token và gửi vào pool CỐ ĐỊNH
// ============================================================================
// Tham số:
// - required_utxo: UTXO bắt buộc phải tiêu thụ (one-shot)
// - total_supply: Tổng số token mint
// - token_name: Tên token
// - pool_script_hash: Script hash của pool_spend validator (địa chỉ cố định)
// - initial_slope: Slope khởi tạo cho bonding curve
// - creator_pkh: Public key hash của creator

validator token_mint(
  required_utxo: OutputReference,
  total_supply: Int,
  token_name: ByteArray,
  pool_script_hash: ByteArray,  // ← Script hash cố định
  initial_slope: Int,
  creator_pkh: ByteArray,
) {
  mint(_redeemer: MintAction, policy_id: PolicyId, tx: Transaction) -> Bool {
    let Transaction { inputs, mint, outputs, .. } = tx
    
    // BƯỚC 1: Kiểm tra UTXO bắt buộc được tiêu thụ (one-shot)
    let utxo_consumed =
      list.any(
        inputs,
        fn(input: Input) {
          let Input { output_reference, .. } = input
          output_reference == required_utxo
        },
      )
    
    // BƯỚC 2: Kiểm tra mint đúng token và số lượng
    let minted_tokens = tokens(mint, policy_id)
    let minted_pairs = dict.to_pairs(minted_tokens)
    
    let correct_mint =
      when minted_pairs is {
        [Pair(name, qty)] ->
          name == token_name && qty == total_supply
        _ -> False
      }
    
    // BƯỚC 3: Kiểm tra token được gửi vào pool với script hash cố định
    let token_sent_to_pool =
      list.any(
        outputs,
        fn(output: Output) {
          let Output { address, value, datum, .. } = output
          let Address { payment_credential, .. } = address
          
          // Kiểm tra địa chỉ là script với hash cố định
          let correct_address =
            when payment_credential is {
              Script(hash) -> hash == pool_script_hash
              _ -> False
            }
          
          // Kiểm tra có đủ token
          let has_token =
            quantity_of(value, policy_id, token_name) == total_supply
          
          // Kiểm tra datum khởi tạo đúng
          let correct_datum =
            when datum is {
              InlineDatum(data) -> {
                expect pool_datum: PoolDatum = data
                // current_supply = 0 (chưa bán token nào)
                pool_datum.current_supply == 0 && 
                pool_datum.slope == initial_slope && 
                pool_datum.token_policy == policy_id && 
                pool_datum.token_name == token_name && 
                pool_datum.creator == creator_pkh
              }
              _ -> False
            }
          
          correct_address && has_token && correct_datum
        },
      )
    
    utxo_consumed && correct_mint && token_sent_to_pool
  }

  else(_) {
    fail
  }
}
