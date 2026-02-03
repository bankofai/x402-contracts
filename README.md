# x402-contracts-tron

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-blue)](https://soliditylang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Smart contracts for the **x402** payment protocol on **TRON**. Enables gasless, signature-based (EIP-712) payment authorizations and TRON-native token settlement.

---

## What is x402?

**[x402](https://www.x402.org/)** is an open, neutral standard for internet-native payments. It brings to life the **HTTP 402 Payment Required** status code so that servers can request payment from clients in a programmatic way—ideal for API paywalls, agent-to-agent payments, and micropayments.

- **Zero protocol fees** — only network fees
- **HTTP-native** — payment flows fit into normal HTTP requests
- **Multi-chain** — this repo provides the **TRON** implementation

---

## Features

- **EIP-712 typed permits** — Users sign payment details off-chain; a relayer or backend calls `permitTransferFrom` with the signature.
- **Gasless for the signer** — The submitter pays gas; the signer only needs a one-time `approve` of the PaymentPermit contract (that approve costs Energy/TRX on first use).
- **TRC20 via SafeTransferLib** — Uses [sun-contract-std](https://github.com/sun-protocol/sun-contract-std) `SafeTransferLib` for TRC20 transfers (handles tokens that do not return a boolean).
- **Optional fee** — Permit can include `feeTo` and `feeAmount` for protocol or facilitator fees.
- **Replay protection** — Nonce bitmap per owner; time window via `validAfter` / `validBefore`.

---

## Architecture

| Component        | Role                         | File(s)                |
|----------------|------------------------------|-------------------------|
| **PaymentPermit** | Entry point for permits and transfers | `contracts/PaymentPermit.sol` |
| **PermitHash** | EIP-712 struct hashes        | `contracts/libraries/PermitHash.sol` |
| **EIP712**     | Domain separator and typed data hashing | `contracts/EIP712.sol` |
| **IPaymentPermit** | Structs and interface for permits | `contracts/interface/IPaymentPermit.sol` |

Flow: **User signs** `PaymentPermitDetails` (payment, fee, validity, nonce) → **Relayer/backend** calls `permitTransferFrom(permit, transferDetails, owner, signature)` → Contract pulls tokens from `owner` to `payTo` (and optional `feeTo`) in one shot.

---

## Deployed Addresses

| Network   | Chain / Environment | PaymentPermit Address |
|-----------|---------------------|------------------------|
| **TRON Mainnet** | Mainnet              | _TBD_                  |
| **Nile**         | Testnet              | `TCR6EaRtLRYjWPr7YWHqt4uL81rfevtE8p` |
| **Shasta**       | Testnet              | `TFiMDs3KeDiwcB5rRBqFHYaNHFZGxEJ89U` |

- **Mainnet**: Production; use after audit and deployment.
- **Nile**: Primary testnet for integration and staging.
- **Shasta**: Alternate testnet.

---

## Requirements

- **Node.js** (e.g. v18+)
- **pnpm** or **npm**
- **Solidity** `^0.8.20` (project uses 0.8.25 in config)
- For TRON deploy: [@sun-protocol/sunhat](https://github.com/sun-protocol/sunhat) and a TRON RPC URL + deployer private key

---

## Quick Start

### Install

```bash
pnpm install
```

Post-install runs `scripts/postinstall.sh` (e.g. submodules or tooling). Ensure it completes successfully.

### Build

```bash
pnpm run compile
# or
forge build
```

### Test

```bash
pnpm run test
# or
forge test -vvv
```

### Deploy (TRON)

1. Copy env example and set TRON RPC and deployer key:

   ```bash
   # .env
   TRON_RPC_URL=https://nile.trongrid.io/jsonrpc   # or mainnet/shasta
   PRIVATE_KEY=your_deployer_private_key_hex
   ```

2. Deploy:

   ```bash
   pnpm run deploy --tags PaymentPermit
   ```

Deploy scripts live in `deploy/` (e.g. `01_deploy_PaymentPermit.ts`). Configure `hardhat.config.ts` for mainnet/nile/shasta as needed.

---

## Project Layout

```
├── contracts/
│   ├── PaymentPermit.sol      # Main permit & transfer logic
│   ├── EIP712.sol             # EIP-712 domain and hashing
│   ├── interface/
│   │   ├── IPaymentPermit.sol # Permit structs and interface
│   │   └── IEIP712.sol
│   └── libraries/
│       └── PermitHash.sol     # TypeHashes and struct hashes
├── deploy/                    # Hardhat deploy scripts (TRON)
├── test/
│   ├── PaymentPermit.t.sol    # Forge/Hardhat tests
│   └── MockERC20.sol
├── hardhat.config.ts         # TRON networks (sunhat)
├── foundry.toml
└── AGENTS.md                  # Guidelines for AI/agent use of this repo
```

---

## Integration

1. **Domain & types** — Use the same EIP-712 domain name `"PaymentPermit"` and the struct definitions from `IPaymentPermit.sol` and `PermitHash.sol` so that hashes match the contract. Domain separator uses `block.chainid` and contract address (see `EIP712.sol`).
2. **ChainId for signing** — When building EIP-712 typed data, use the chainId of the target network so the signature matches the contract: **Mainnet** `0x2b67540c`, **Nile** `0xcd8690dc`, **Shasta** `0x94a9059e`. Wallet/TronLink must use the same chainId.
3. **Sign off-chain** — Build `PaymentPermitDetails` (meta, buyer, caller, payment, fee, delivery), hash with `PermitHash` and domain separator, then sign (e.g. 65-byte `r || s || v`).
4. **Submit on-chain** — Call `permitTransferFrom(permit, transferDetails, owner, signature)`. The `owner` must have approved the PaymentPermit contract for the `payToken` (and have sufficient balance for `amount` plus optional `feeAmount`).
5. **TRC20** — The contract uses `SafeTransferLib` for TRC20 transfers; tokens that do not return a boolean are handled by the library.

For full struct and field definitions, see `contracts/interface/IPaymentPermit.sol`.

---

## Security

- **Audits**: Check the repo for any `audit_report.md` or audit notes; apply recommendations before mainnet use.
- **Access**: Only the signer’s signature authorizes transfers; no single admin can move user funds.
- **Replay**: Nonces and `validAfter`/`validBefore` limit replay across chains and time.

We welcome responsible disclosure. Please report issues privately before public disclosure when possible.

---

## License

[MIT](LICENSE). See [LICENSE](LICENSE) for full text.

---

## Contributing

1. Fork the repo and open a branch from `main`.
2. Follow existing style (Solidity ^0.8.20, existing patterns in `PaymentPermit.sol` and `PermitHash.sol`).
3. Add or update tests for new behavior.
4. Open a PR with a clear description; maintainers will review.

For agent/AI usage of this codebase, see [AGENTS.md](AGENTS.md).
