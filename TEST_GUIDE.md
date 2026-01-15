# Hướng dẫn Test One-Shot Mint Validator

## Tổng quan

Bạn đã có một ứng dụng web hoàn chỉnh để test validator one-shot mint trên Cardano Preprod testnet.

## Cấu trúc Project

```
smc_pump/
├── validators/
│   ├── one_shot_mint.ak           # Validator chính
│   └── test_one_shot_mint.ak      # Unit tests
├── plutus.json                    # Compiled validator
└── frontend/                      # Web application
    ├── src/
    │   ├── app/page.tsx          # Main page
    │   └── components/OneShotMint.tsx
    ├── public/plutus.json        # Copy của validator
    └── .env.local                # Blockfrost API key
```

## Bước 1: Chuẩn bị Wallet

### 1.1 Cài đặt Wallet
- Cài đặt [Nami Wallet](https://namiwallet.io/) extension
- Hoặc [Eternl](https://eternl.io/) hoặc [Flint](https://flint-wallet.com/)

### 1.2 Chuyển sang Preprod Testnet
- Mở wallet settings
- Chuyển network từ Mainnet sang **Preprod Testnet**

### 1.3 Lấy Testnet ADA
- Truy cập [Cardano Testnet Faucet](https://docs.cardano.org/cardano-testnet/tools/faucet/)
- Nhập địa chỉ wallet của bạn
- Nhận 1000 tADA (testnet ADA)

## Bước 2: Chạy Ứng dụng

### 2.1 Start Frontend
```bash
cd smc_pump/frontend
npm run dev
```

### 2.2 Mở Browser
- Truy cập http://localhost:3000
- Bạn sẽ thấy giao diện "One-Shot NFT Minting"

## Bước 3: Test Scenarios

### Scenario 1: Mint thành công (Pass)

1. **Connect Wallet**
   - Click "Connect Wallet"
   - Chọn wallet (Nami/Eternl/Flint)
   - Authorize connection

2. **Select UTxO**
   - Xem danh sách UTxOs trong wallet
   - Chọn một UTxO bất kỳ (thường chọn UTxO đầu tiên)

3. **Mint NFT**
   - Click "Mint One-Shot NFT"
   - Confirm transaction trong wallet
   - Đợi transaction được submit

4. **Kết quả mong đợi**
   - ✅ Transaction thành công
   - Hiển thị transaction hash
   - Link đến CardanoScan Preprod

### Scenario 2: Mint lần 2 với cùng UTxO (Fail)

1. **Thử mint lại**
   - Sau khi mint thành công ở Scenario 1
   - UTxO đã được consume, không còn trong danh sách
   - Hoặc nếu chọn UTxO khác, sẽ thành công

2. **Kết quả mong đợi**
   - ❌ Không thể chọn UTxO đã sử dụng
   - Hoặc transaction fail nếu somehow vẫn submit được

### Scenario 3: Test với nhiều UTxOs

1. **Tạo nhiều UTxOs**
   - Send ADA cho chính mình để tạo nhiều UTxOs
   - Hoặc nhận từ faucet nhiều lần

2. **Mint từng UTxO**
   - Mỗi UTxO có thể mint 1 NFT
   - Sau khi mint, UTxO biến mất khỏi danh sách

3. **Kết quả mong đợi**
   - ✅ Mỗi UTxO mint được 1 NFT duy nhất
   - Không thể reuse UTxO đã dùng

## Bước 4: Verify On-Chain

### 4.1 Check Transaction
- Click link CardanoScan trong kết quả
- Xem transaction details
- Verify mint 1 NFT với policy ID

### 4.2 Check Wallet Assets
- Mở wallet
- Xem tab Assets/NFTs
- Confirm NFT đã được mint

### 4.3 Check UTxO Consumption
- Trong CardanoScan, xem inputs của transaction
- Verify UTxO đã được consume

## Debugging

### Console Logs
- Mở Developer Tools (F12)
- Xem Console tab để debug
- Logs hiển thị:
  - Script loading
  - UTxO selection
  - Transaction building
  - Submission results

### Common Issues

1. **Wallet không connect**
   - Refresh page
   - Check wallet extension enabled
   - Ensure on Preprod testnet

2. **No UTxOs available**
   - Check wallet có ADA
   - Đợi transaction confirm từ faucet

3. **Transaction fail**
   - Check đủ ADA cho fees
   - Verify UTxO chưa được sử dụng
   - Check console errors

## Kết luận

Validator hoạt động đúng nếu:
- ✅ Mint thành công với UTxO mới
- ❌ Không thể mint lại với UTxO đã dùng
- ✅ Chỉ mint được đúng 1 NFT mỗi lần
- ✅ Transaction được confirm on-chain

Đây là proof-of-concept hoàn chỉnh cho one-shot mint validator trên Cardano!