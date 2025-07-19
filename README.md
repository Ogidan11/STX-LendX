
# STX-LendX Lending Pool Smart Contract (Stacks / Clarity)

A decentralized STX-based lending protocol implemented in Clarity, allowing users to:

* Deposit STX and earn interest
* Borrow STX against their deposits
* Be liquidated if undercollateralized
* Participate in flash loans
* Administer protocol parameters with governance-level access

---

## 📜 Contract Overview

This smart contract provides a secure, STX-native lending pool. It includes:

* **Collateralized lending**
* **Interest accrual**
* **Liquidation mechanics**
* **Flash loans**
* **Administrative controls**
* **Event logging for all key operations**

---

## 📂 Table of Contents

* [Contract Features](#contract-features)
* [Data Structures](#data-structures)
* [Core Functions](#core-functions)
* [Admin Functions](#admin-functions)
* [Read-Only Functions](#read-only-functions)
* [Collateral and Liquidation Logic](#collateral-and-liquidation-logic)
* [Interest Accrual](#interest-accrual)
* [Flash Loan Details](#flash-loan-details)
* [Deployment Note](#deployment-note)
* [License](#license)

---

## 🚀 Contract Features

| Feature           | Description                                                           |
| ----------------- | --------------------------------------------------------------------- |
| `deposit`         | Deposit STX into the lending pool                                     |
| `withdraw`        | Withdraw STX from the pool (if overcollateralized)                    |
| `borrow`          | Borrow STX against deposited collateral                               |
| `repay`           | Repay borrowed STX                                                    |
| `liquidate`       | Liquidate undercollateralized positions                               |
| `accrue-interest` | Accrue interest on borrowed STX                                       |
| `flash-loan`      | Borrow STX instantly and repay within the same transaction (0.1% fee) |
| `admin`           | Adjust protocol parameters and pause/unpause the contract             |

---

## 🧱 Data Structures

### Constants

```clarity
CONTRACT_OWNER
ERR_UNAUTHORIZED
ERR_INSUFFICIENT_BALANCE
ERR_INSUFFICIENT_COLLATERAL
ERR_INVALID_AMOUNT
ERR_PAUSED
ERR_INVALID_RATIO
ERR_INVALID_RATE
ERR_LIQUIDATION_FAILED
```

### Data Vars

| Variable                | Description                         |
| ----------------------- | ----------------------------------- |
| `min-collateral-ratio`  | Minimum required ratio (e.g. 150%)  |
| `liquidation-threshold` | Liquidation point (e.g. 120%)       |
| `interest-rate`         | Annual interest rate (e.g. 5%)      |
| `liquidation-fee`       | Fee added on liquidation (e.g. 5%)  |
| `paused`                | Pause/unpause contract interactions |
| `total-deposits`        | Track all deposits in the system    |
| `total-borrows`         | Track all outstanding borrows       |

### Maps

* `user-deposits { user: principal } → { amount, last-update }`
* `user-borrows { user: principal } → { amount, last-update }`
* `whitelisted-liquidators { user: principal } → { active: bool }`

---

## ⚙️ Core Functions

### Deposit

```clarity
(deposit (amount uint))
```

* Transfers `amount` of STX from user to contract.
* Updates deposit balance and emits a `deposit` event.

### Withdraw

```clarity
(withdraw (amount uint))
```

* Only possible if resulting collateral ratio remains above the required threshold.
* Transfers STX back to the user.

### Borrow

```clarity
(borrow (amount uint))
```

* Requires sufficient collateral ratio.
* Increases user’s borrow amount and transfers STX to them.

### Repay

```clarity
(repay (amount uint))
```

* Transfers STX from user to repay loan.
* Updates borrow balance and emits a `repay` event.

---

## 🔥 Liquidation

### Liquidate Underwater Accounts

```clarity
(liquidate (borrower principal) (amount uint))
```

* Anyone can liquidate an undercollateralized user.
* Repays `amount` of borrower’s debt and receives `amount + fee` worth of collateral.
* Emits `liquidation` event.

---

## 📈 Interest Accrual

```clarity
(accrue-interest (user principal))
```

* Calculates interest based on `blocks-elapsed`.
* Adds interest to borrower’s debt.
* Emits `interest-accrued` event.

---

## ⚡ Flash Loans

```clarity
(flash-loan (amount uint) (recipient principal) (memo optional(buff 34)))
```

* Transfers `amount` STX to `recipient`.
* Ensures `amount + fee (0.1%)` is returned in the same transaction.
* Adds fee to `total-deposits`.

---

## 🛡️ Admin Functions

| Function                    | Purpose                                |
| --------------------------- | -------------------------------------- |
| `set-collateral-ratio`      | Set `min-collateral-ratio`             |
| `set-liquidation-threshold` | Set the liquidation threshold          |
| `set-interest-rate`         | Set the annual interest rate           |
| `set-liquidation-fee`       | Set the fee applied during liquidation |
| `toggle-pause`              | Pause/unpause all contract operations  |

> All admin functions require `tx-sender == CONTRACT_OWNER`.

---

## 🔍 Read-Only Functions

| Function                     | Description                                           |
| ---------------------------- | ----------------------------------------------------- |
| `get-deposit`                | Returns deposit amount for a user                     |
| `get-borrow`                 | Returns borrow amount for a user                      |
| `get-total-deposits`         | Returns total STX deposited                           |
| `get-total-borrows`          | Returns total STX borrowed                            |
| `check-collateral-ratio`     | Verifies if a user’s collateral meets the threshold   |
| `calculate-collateral-ratio` | Calculates user's collateral-to-debt ratio            |
| `is-underwater`              | Returns `true` if user is below liquidation threshold |

---

## 💡 Collateral and Liquidation Logic

* **Minimum Collateral Ratio**: Must be ≥ 150% (default)
* **Liquidation Threshold**: If collateral ratio < 120%, liquidation is possible.
* **Liquidation Penalty**: Liquidator receives borrower collateral + 5% bonus.
* **Interest Accrual**: Compounds per block based on an annualized rate.

---

## 🛠 Deployment Note

```clarity
(begin
  (try! (stx-transfer? u1000000000 CONTRACT_OWNER (as-contract tx-sender)))
  (ok true))
```

> This initialization block transfers an initial STX amount to the contract during deployment. Adjust as needed.

---