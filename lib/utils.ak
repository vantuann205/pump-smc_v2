use aiken/builtin
use aiken/primitive/bytearray
use cardano/assets.{AssetName, PolicyId, Value, quantity_of}
use cardano/transaction.{Input, Output, OutputReference}
use types.{PoolDatum}

pub const cip67_ref_label = #"000643b0"

// Các hàm helper chung cho mint và pool
pub fn calculate_buy_price(datum: PoolDatum, amount: Int) -> Int {
  let s = datum.current_supply
  datum.slope * amount * (2 * s + amount - 1) / (2 * datum.scale)
}

pub fn calculate_sell_price(datum: PoolDatum, amount: Int) -> Int {
  let s = datum.current_supply
  datum.slope * amount * (2 * s - amount + 1) / (2 * datum.scale)
}

pub fn quantity_of_token(value: Value, policy: ByteArray, name: ByteArray) -> Int {
  quantity_of(value, policy, name)
}

pub fn get_single_asset_from_value(v: Value) -> (PolicyId, AssetName, Int) {
  // A single asset was expected.
  expect [triplet] =
    v
      |> assets.flatten
  triplet
}

pub fn validate_mint_labels(
  triplet0: (PolicyId, AssetName, Int),
  triplet1: (PolicyId, AssetName, Int),
) -> ((PolicyId, AssetName, Int), (PolicyId, AssetName, Int)) {
  let (_, t0, _) = triplet0
  let (_, t1, _) = triplet1
  let l0IsCip67 = bytearray.take(t0, 4) == cip67_ref_label
  let l1IsCip67 = bytearray.take(t1, 4) == cip67_ref_label
  if l0IsCip67 && !l1IsCip67 {
    (triplet0, triplet1)
  } else if !l0IsCip67 && l1IsCip67 {
    (triplet1, triplet0)
  } else {
    // Exactly one of the two mints must be prefixed with CIP-67 `100`
    fail
  }
}

// Copied over from the Fortuna repo:
// https://github.com/cardano-miners/fortuna/blob/32a5edf5b56c8d8a97c45eae254a70d1c66bd972/lib/fortuna/utils.ak#L6-L17
pub fn resolve_output_reference(
  inputs: List<Input>,
  output_ref: OutputReference,
) -> Output {
  expect [input, ..] = inputs
  if input.output_reference == output_ref {
    input.output
  } else {
    resolve_output_reference(builtin.tail_list(inputs), output_ref)
  }
}