use aiken/collection/list
use cardano/address.{Address, Script}
use cardano/assets.{PolicyId, ada_asset_name, ada_policy_id, flatten, quantity_of}
use cardano/transaction.{InlineDatum, Input, Output, OutputReference, Transaction}

pub type Action {
  Buy { amount: Int, max_cost: Int }
  Sell { amount: Int, min_refund: Int }
  AdminWithdraw { ada_amount: Int }
  Commit
}

pub type PoolDatum {
  token_policy: PolicyId,
  token_name: ByteArray,
  slope: Int,
  current_supply: Int,
  creator: ByteArray,
}

const min_ada_in_pool: Int = 2_000_000
const max_supply: Int = 1_000_000_000

fn calculate_cost(slope: Int, supply_start: Int, supply_end: Int) -> Int {
  let end_squared = supply_end * supply_end
  let start_squared = supply_start * supply_start
  slope * (end_squared - start_squared) / 2
}

validator pump_pool(_dummy: Int) {
  spend(
    datum_opt: Option<PoolDatum>,
    redeemer: Action,
    _output_ref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = datum_opt

    let Transaction { inputs, outputs, extra_signatories, .. } = tx

    expect Some(own_input) =
      list.find(
        inputs,
        fn(input: Input) {
          let Input { output, .. } = input
          let Output { address, .. } = output
          let Address { payment_credential, .. } = address
          when payment_credential is {
            Script(_) -> True
            _ -> False
          }
        },
      )

    let Input { output: own_output, .. } = own_input
    let Output { value: input_value, address: pool_address, .. } = own_output

    when redeemer is {
      Commit -> {
        True
      }

      Buy { amount, max_cost } -> {
        expect Some(continuing_output) =
          list.find(
            outputs,
            fn(output: Output) {
              let Output { address, .. } = output
              address == pool_address
            },
          )

        let Output { value: output_value, datum: output_datum_inline, .. } =
          continuing_output

        expect InlineDatum(output_datum_data) = output_datum_inline
        expect new_datum: PoolDatum = output_datum_data

        let output_assets = flatten(output_value)
        let output_tokens_count =
          quantity_of(output_value, datum.token_policy, datum.token_name)

        let expected_asset_count =
          if output_tokens_count == 0 { 1 } else { 2 }

        expect list.length(output_assets) == expected_asset_count

        let asset_check =
          if output_tokens_count > 0 {
            list.any(
              output_assets,
              fn(asset) {
                let (policy, name, _) = asset
                policy == datum.token_policy && name == datum.token_name
              },
            )
          } else {
            True
          }

        expect asset_check

        expect amount > 0

        let old_supply = datum.current_supply
        let new_supply = old_supply + amount
        expect new_supply <= max_supply

        let cost = calculate_cost(datum.slope, old_supply, new_supply)
        expect cost > 0
        expect cost <= max_cost

        expect new_datum.current_supply == new_supply
        expect new_datum.token_policy == datum.token_policy
        expect new_datum.token_name == datum.token_name
        expect new_datum.slope == datum.slope
        expect new_datum.creator == datum.creator

        let input_ada =
          quantity_of(input_value, ada_policy_id, ada_asset_name)
        let output_ada =
          quantity_of(output_value, ada_policy_id, ada_asset_name)
        expect output_ada - input_ada == cost

        let input_tokens =
          quantity_of(input_value, datum.token_policy, datum.token_name)
        let output_tokens =
          quantity_of(output_value, datum.token_policy, datum.token_name)
        expect input_tokens - output_tokens == amount

        True
      }

      Sell { amount, min_refund } -> {
        expect Some(continuing_output) =
          list.find(
            outputs,
            fn(output: Output) {
              let Output { address, .. } = output
              address == pool_address
            },
          )

        let Output { value: output_value, datum: output_datum_inline, .. } =
          continuing_output

        expect InlineDatum(output_datum_data) = output_datum_inline
        expect new_datum: PoolDatum = output_datum_data

        expect amount > 0

        let old_supply = datum.current_supply
        let new_supply = old_supply - amount
        expect new_supply >= 0

        let refund =
          calculate_cost(datum.slope, new_supply, old_supply)
        expect refund >= min_refund

        expect new_datum.current_supply == new_supply
        expect new_datum.token_policy == datum.token_policy
        expect new_datum.token_name == datum.token_name
        expect new_datum.slope == datum.slope
        expect new_datum.creator == datum.creator

        let input_ada =
          quantity_of(input_value, ada_policy_id, ada_asset_name)
        let output_ada =
          quantity_of(output_value, ada_policy_id, ada_asset_name)
        expect input_ada - output_ada == refund
        expect output_ada >= min_ada_in_pool

        let input_tokens =
          quantity_of(input_value, datum.token_policy, datum.token_name)
        let output_tokens =
          quantity_of(output_value, datum.token_policy, datum.token_name)
        expect output_tokens - input_tokens == amount

        True
      }

      AdminWithdraw { ada_amount } -> {
        expect Some(continuing_output) =
          list.find(
            outputs,
            fn(output: Output) {
              let Output { address, .. } = output
              address == pool_address
            },
          )

        let Output { value: output_value, datum: output_datum_inline, .. } =
          continuing_output

        expect InlineDatum(output_datum_data) = output_datum_inline
        expect new_datum: PoolDatum = output_datum_data

        expect ada_amount > 0
        expect list.has(extra_signatories, datum.creator)

        expect new_datum.current_supply == datum.current_supply
        expect new_datum.token_policy == datum.token_policy
        expect new_datum.token_name == datum.token_name
        expect new_datum.slope == datum.slope
        expect new_datum.creator == datum.creator

        let input_ada =
          quantity_of(input_value, ada_policy_id, ada_asset_name)
        let output_ada =
          quantity_of(output_value, ada_policy_id, ada_asset_name)
        expect input_ada - output_ada == ada_amount

        let theoretical_reserve =
          calculate_cost(datum.slope, 0, datum.current_supply)

        let max_withdrawable =
          if input_ada > theoretical_reserve + min_ada_in_pool {
            input_ada - (theoretical_reserve + min_ada_in_pool)
          } else {
            0
          }

        expect ada_amount <= max_withdrawable

        let input_tokens =
          quantity_of(input_value, datum.token_policy, datum.token_name)
        let output_tokens =
          quantity_of(output_value, datum.token_policy, datum.token_name)
        expect input_tokens == output_tokens

        True
      }
    }
  }

  else(_) {
    fail
  }
}
