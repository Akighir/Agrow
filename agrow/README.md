# Agrow: Urban Farming Collective Smart Contract

Agrow is a Clarity smart contract enabling fractional ownership, decentralized decision-making, and automated revenue sharing in vertical urban farming projects. Designed for collective farming operations, Agrow empowers growers to lease plots, vote on harvest proposals, and receive crop revenue distributions — all on-chain.

---

## 🌱 Features

- **Farm Creation**: Coordinators can register vertical farms with specified locations, plots, and revenue structures.
- **Plot Leasing**: Growers can lease farm plots and become stakeholders.
- **Harvest Proposals**: Growers can propose crop types and methods for upcoming harvests.
- **Governance Voting**: Stake-based voting on harvest proposals ensures decentralized decision-making.
- **Revenue Distribution**: Automates proportional distribution of crop sales revenue to plot owners.
- **Claim Tracking**: Ensures growers only claim revenue once per cycle.
- **Transparency**: Public access to farm, plot, and harvest data via read-only functions.

---

## 🧱 Contract Architecture

### Constants
- `FARM_COORDINATOR`: Creator or managing authority.
- Custom error codes (e.g., `ERR_UNAUTHORIZED_GROWER`, `ERR_HARVEST_NOT_FOUND`) ensure clarity in failure cases.

### Data Storage
- `vertical-farms`: Stores metadata about each farm.
- `grower-plots`: Tracks how many plots each grower leases.
- `crop-harvests`: Records proposals for each harvest cycle.
- `harvest-votes`: Prevents double-voting and records voter stance.
- `sales-claims`: Prevents duplicate claims per revenue cycle.

---

## 🔐 Core Public Functions

| Function | Description |
|---------|-------------|
| `establish-farm` | Registers a new vertical farm. |
| `lease-plots` | Allows a grower to lease plots in a registered farm. |
| `create-harvest` | Proposes a new harvest with crop and method details. |
| `vote-harvest` | Lets growers vote for or against harvest proposals. |
| `distribute-sales` | Triggers revenue distribution after a harvest cycle. |
| `claim-sales` | Allows a grower to claim their revenue share. |

---

## 🧾 Read-Only Functions

| Function | Description |
|---------|-------------|
| `get-farm` | Returns full metadata of a specified farm. |
| `get-plot-balance` | Returns number of plots owned by a grower. |
| `get-harvest` | Returns details of a specific harvest proposal. |
| `calculate-sales-share` | Computes a grower’s eligible revenue based on plots. |

---

## 📦 Example Workflow

1. **Farm Establishment** by the FARM_COORDINATOR.
2. **Growers Lease Plots** via `lease-plots`.
3. **Harvest Proposal** is created by any plot-holder.
4. **Community Voting** determines approval.
5. **Coordinator Distributes Revenue** using `distribute-sales`.
6. **Growers Claim Share** using `claim-sales`.

---

## 🚫 Error Handling

Custom error codes ensure robust logic and clear failure modes:
- `ERR_UNAUTHORIZED_GROWER`
- `ERR_FARM_NOT_FOUND`
- `ERR_INVALID_AMOUNT`
- `ERR_ALREADY_VOTED`
- and more.

---

## 🧪 Testing Recommendations

- Validate proposal voting deadlines (`block-height` based).
- Ensure only plot-holding growers can vote or propose.
- Test correct proportional revenue calculation.
- Prevent double claims per cycle.

---


## 🌐 Use Cases

- Urban cooperative vertical farms
- DAO-governed agricultural collectives
- Decentralized food sovereignty projects
