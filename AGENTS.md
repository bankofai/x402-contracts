# AGENTS.md

> [!NOTE]
> This is a machine-readable open standard for AI coding agents to understand the x402-contracts project.

## 1. Project Context
x402-contracts is a modular decentralized payment and delivery protocol implementation. It separates the payment authorization (via EIP-712 permits) from the actual fulfillment/delivery (via callback agents).

**Core Mission**: Enable gasless, atomic "Payment-then-Delivery" cycles.

---

## 2. Environment & Setup

### Requirements
- **Solidity Version**: `^0.8.20`
- **Dependency Management**: Standard Foundry/Hardhat environment.
- **Key Libraries**:
    - `solmate`: Used for standard ERC20 operations.
    - `sun-contract-std`: Critical for TRON network compatibility (USDT).

### Build & Test
- Build: `npx hardhat compile` or `forge build`
- Test: `npx hardhat test` or `forge test`

---

## 3. Core Architecture for AI Agents

When interacting with this codebase, AI agents must understand the following mapping:

| Component | Responsibility | Relevant Files |
| :--- | :--- | :--- |
| **Payment Hub** | Entry point for EIP-712 permits and cash flow. | `PaymentPermit.sol` |
| **Interface** | Defines the "Contract" between Hub and Agents. | `IAgentExecInterface.sol` |
| **Logic Libraries** | Hash calculation and safe transfers. | `PermitHash.sol`, `SafeTransferLib.sol` |
| **Agents** | Fulfillment logic (NFT minting, tokens, etc.). | `contracts/merchant_demo/MerchantAgent.sol` |

---

## 4. Coding & Security Guardrails (STRICT)

### AI Constraint 1: Access Control (MANDATORY)
Every implementation of an Agent's `Execute` function **MUST** include a caller restriction to ensure only the authorized `PaymentPermit` contract can trigger it.

```solidity
// Required pattern for AI generated agents
modifier onlyPaymentPermit() {
    require(msg.sender == paymentPermit, "Unauthorized");
    _;
}
```

### AI Constraint 2: Signature Integrity
The `permitTransferFromWithCallback` expects that **all** critical parameters (including delivery details) are covered by the user's signature.
- **Reference**: `PermitHash.sol` for TypeHash definitions.
- **Constraint**: Do not implement callbacks that rely on unsigned `data` for pricing or critical asset distribution.

### AI Constraint 3: TRON USDT Compatibility
When generating transfer code for USDT on TRON (Nile/Mainnet), agents **MUST** use `SafeTransferLib` to handle non-returning boolean calls.

---

## 5. Typical Workflows for AI

### Workflow A: Adding a new Fulfillment Agent
1. Create a contract inheriting `IAgentExecInterface`.
2. Implement `Execute(bytes calldata data)`.
3. Apply `onlyPaymentPermit` modifier.
4. Add E2E tests in `test/` ensuring the callback is correctly triggered by `PaymentPermit`.

### Workflow B: Modifying Permitted Data
1. Update `IPaymentPermit.sol` structs.
2. Update `PermitHash.sol` TypeHash strings and `hash()` functions.
3. Regenerate client-side signing logic.

---

## 6. Resources & Knowledge Base
- **Audit Findings**: Refer to `audit_report.md` for historical vulnerabilities and mitigations.
- **API Spec**: See `IPaymentPermit.sol` for a complete description of available endpoints.
