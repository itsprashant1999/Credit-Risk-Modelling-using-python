# Leakage Exclusion List — Credit Risk PD Engine

**Rule:** a PD model may only use information available **at the moment of application**.
Any column populated *after* the loan is funded encodes the outcome and must be excluded.
This document lists every excluded column and why — it is the answer to interview question #1:
*"which columns did you exclude, and why?"*

Source: `accepted_2007_to_2018Q4.csv.gz` — 151 columns.

---

## 0. Target (not a feature)
- `loan_status` — source of the binary default label. Becomes `y`; never an input.

## 1. Leakage — post-origination payment & performance
Recorded over the life of the loan = the repayment outcome itself.
- `out_prncp`, `out_prncp_inv` — outstanding principal (shrinks as they pay)
- `total_pymnt`, `total_pymnt_inv` — total paid to date
- `total_rec_prncp`, `total_rec_int`, `total_rec_late_fee` — principal / interest / late fees received
- `recoveries`, `collection_recovery_fee` — post-charge-off recovery (only exists if defaulted)
- `last_pymnt_d`, `last_pymnt_amnt`, `next_pymnt_d` — payment history / schedule
- `last_credit_pull_d` — LC re-pulls credit *during* the loan (post-origination date)
- `last_fico_range_high`, `last_fico_range_low` — FICO **updated after** origination
- `pymnt_plan` — payment-plan flag (set when a borrower is already struggling)

## 2. Leakage — hardship program
Only populated if the borrower entered hardship → pure future knowledge.
- `hardship_flag`, `hardship_type`, `hardship_reason`, `hardship_status`, `deferral_term`,
  `hardship_amount`, `hardship_start_date`, `hardship_end_date`, `payment_plan_start_date`,
  `hardship_length`, `hardship_dpd`, `hardship_loan_status`,
  `orig_projected_additional_accrued_interest`, `hardship_payoff_balance_amount`,
  `hardship_last_payment_amount`

## 3. Leakage — debt settlement
Only populated if the loan went to settlement (i.e., went bad).
- `debt_settlement_flag`, `debt_settlement_flag_date`, `settlement_status`, `settlement_date`,
  `settlement_amount`, `settlement_percentage`, `settlement_term`

## 4. Excluded by judgment — Lending Club's own risk pricing
Known at origination, but these ARE LC's risk model. Using them = re-predicting LC's decision
instead of modeling default. Excluded so the model is **independent**; LC `grade` may be kept
*separately* only as a benchmark to beat.
- `grade`, `sub_grade`, `int_rate`
- `installment` — derived from `loan_amnt` + `int_rate` + `term`, so it smuggles `int_rate` back in

## 5. Excluded — identifiers, free text, constants
Not predictive and/or post-approval bookkeeping.
- `id`, `member_id` — row identifiers
- `url` — link to the loan page (identifier)
- `policy_code` — constant (= 1 for all accepted loans)
- `funded_amnt`, `funded_amnt_inv` — amount funded *after* approval; ≈ `loan_amnt` (redundant)
- `emp_title`, `title`, `desc` — high-cardinality free text; not leakage, but dropped for the
  baseline (could be revisited with NLP later)

## 6. Time key (not a feature)
- `issue_d` — loan issue month; used to build the out-of-time vintage split, not as a predictor.

---

## Allowed feature set
Everything **not** listed above: the borrower's application-time profile and credit-bureau
attributes — e.g. `loan_amnt`, `term`, `emp_length`, `home_ownership`, `annual_inc`, `dti`,
`fico_range_low/high`, `earliest_cr_line`, `revol_util`, `open_acc`, `pub_rec`, the
`num_*` / `mo_sin_*` / `*_il` / `*_bc` bureau fields, and `sec_app_*` for joint applications.
These are all known at application and are the legitimate inputs to the model.

**Missingness note:** many bureau fields (≈ cols 63–127) are only populated for later vintages.
Missingness is treated as signal in Phase 4 — not dropped blindly.

---

**Implementation (cross-checked):** 53 columns excluded → **98 allowed features**.
- pandas: `reports/allowed_features.txt` (from `notebooks/01_data_understanding.ipynb`)
- SQL: the `accepted_features` view in `data/credit.duckdb` via `SELECT * EXCLUDE (...)`
  (`notebooks/01_data_understanding_sql.ipynb` / `sql/01_data_understanding.sql`)
