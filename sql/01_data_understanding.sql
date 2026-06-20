-- Credit Risk PD Engine - Data Understanding in SQL (DuckDB)
-- Mirrors notebooks/01_data_understanding.ipynb (pandas).
-- Run all:  duckdb data/credit.duckdb < sql/01_data_understanding.sql


-- ==================================================================
--  Phase 1.5 - Profile the accepted table
-- ==================================================================
-- rows in the table
SELECT COUNT(*) AS rows FROM accepted;

-- column names + DuckDB-inferred types
DESCRIBE accepted;

-- eyeball the first rows
SELECT * FROM accepted LIMIT 5;

-- target distribution (the raw material for Phase 3)
SELECT loan_status, COUNT(*) AS n
FROM accepted
GROUP BY loan_status
ORDER BY n DESC;

-- junk rows: real loans always have a loan_amnt
SELECT COUNT(*) AS junk_rows FROM accepted WHERE loan_amnt IS NULL;


-- ==================================================================
--  Phase 1.6 - Inspect the rejected table (column names have spaces -> use double quotes)
-- ==================================================================
SELECT COUNT(*) AS rows FROM rejected;

-- SUMMARIZE = DuckDB's describe: min/max/avg/nulls per column
SUMMARIZE rejected;

SELECT * FROM rejected LIMIT 5;

-- Policy Code should be a single constant value (useless predictor)
SELECT "Policy Code", COUNT(*) AS n
FROM rejected
GROUP BY "Policy Code";


-- ==================================================================
--  Phase 2 - Leakage-safe feature view (SELECT * EXCLUDE drops the 53 banned columns)
-- ==================================================================
CREATE OR REPLACE VIEW accepted_features AS
SELECT * EXCLUDE (
    "loan_status",
    "issue_d",
    "out_prncp",
    "out_prncp_inv",
    "total_pymnt",
    "total_pymnt_inv",
    "total_rec_prncp",
    "total_rec_int",
    "total_rec_late_fee",
    "recoveries",
    "collection_recovery_fee",
    "last_pymnt_d",
    "last_pymnt_amnt",
    "next_pymnt_d",
    "last_credit_pull_d",
    "last_fico_range_high",
    "last_fico_range_low",
    "pymnt_plan",
    "hardship_flag",
    "hardship_type",
    "hardship_reason",
    "hardship_status",
    "deferral_term",
    "hardship_amount",
    "hardship_start_date",
    "hardship_end_date",
    "payment_plan_start_date",
    "hardship_length",
    "hardship_dpd",
    "hardship_loan_status",
    "orig_projected_additional_accrued_interest",
    "hardship_payoff_balance_amount",
    "hardship_last_payment_amount",
    "debt_settlement_flag",
    "debt_settlement_flag_date",
    "settlement_status",
    "settlement_date",
    "settlement_amount",
    "settlement_percentage",
    "settlement_term",
    "grade",
    "sub_grade",
    "int_rate",
    "installment",
    "id",
    "member_id",
    "url",
    "policy_code",
    "funded_amnt",
    "funded_amnt_inv",
    "emp_title",
    "title",
    "desc"
)
FROM accepted;

-- confirm 98 allowed columns remain
SELECT COUNT(*) AS allowed_cols
FROM information_schema.columns
WHERE table_name = 'accepted_features';


-- ==================================================================
--  Phase 3 - Define the binary target on RESOLVED loans only
-- ==================================================================
CREATE OR REPLACE VIEW model_data AS
SELECT *,
  CASE WHEN loan_status IN ('Charged Off','Default') THEN 1
       WHEN loan_status = 'Fully Paid'              THEN 0 END AS target
FROM accepted
WHERE loan_status IN ('Fully Paid','Charged Off','Default');

-- class balance
SELECT target, COUNT(*) AS n FROM model_data GROUP BY target ORDER BY target;

-- cohort size + default rate
SELECT COUNT(*) AS rows, ROUND(AVG(target), 4) AS default_rate FROM model_data;

