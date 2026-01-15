// Định nghĩa chung cho các validator
use cardano/address.{Address}

pub type ActionMint {
  Mint
}

pub type ActionPool {
  Buy { amount: Int, buyer_address: Address }
  Sell { amount: Int, seller_address: Address }
}

pub type PoolDatum {
  current_supply: Int,      // Số token hiện có trong pool
  slope: Int,               // Slope của bonding curve
  scale: Int,               // Scale để chia số
  treasury: Int,            // Số lovelace hiện có trong pool
  token_policy: ByteArray,  // Policy ID của token
  token_name: ByteArray     // Tên token
}