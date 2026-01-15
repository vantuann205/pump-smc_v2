use aiken/collection/dict
use aiken/collection/list
use cardano/assets.{PolicyId, tokens}
use cardano/transaction.{Input, OutputReference, Transaction}

pub type MintRedeemer {
  Mint
}

validator mint_policy(required_tx_hash: ByteArray, required_output_index: Int) {
  mint(_redeemer: MintRedeemer, policy_id: PolicyId, tx: Transaction) {
    let Transaction { inputs, mint, .. } = tx
    
    let required_utxo =
      OutputReference {
        transaction_id: required_tx_hash,
        output_index: required_output_index,
      }
    
    let utxo_consumed =
      list.any(
        inputs,
        fn(input: Input) {
          let Input { output_reference, .. } = input
          output_reference == required_utxo
        },
      )
    
    let minted_tokens = tokens(mint, policy_id)
    let minted_assets = dict.to_pairs(minted_tokens)
    
    let single_token_minted =
      when minted_assets is {
        [Pair(_, quantity)] -> quantity > 0
        _ -> False
      }
    
    utxo_consumed && single_token_minted
  }

  else(_) {
    fail
  }
}
