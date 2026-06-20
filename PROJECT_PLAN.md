# Project Plan & Progress Tracker

Phase-by-phase build plan for the Credit Risk PD Engine. Check off substeps as we complete
them. Each phase maps to a specific phrase on the resume line it backs.

Legend: `[ ]` todo · `[~]` in progress · `[x]` done

---

## Phase 0 — Environment & Repo Setup
- [x] 0.1 Create virtual environment (`.venv`)
- [x] 0.2 Activate venv
- [x] 0.3 Folder structure (`data/ notebooks/ src/ models/ reports/`)
- [x] 0.4 `requirements.txt`
- [x] 0.5 `.gitignore`
- [x] 0.6 `pip install -r requirements.txt` (into .venv)
- [x] 0.7 git identity + first commit + push to GitHub

## Phase 1 — Data Acquisition & Verification  _(backs "2.2M loans" + "27M rejected")_
- [x] 1.1 Kaggle token / download
- [x] 1.2 Download `wordsforthewise/lending-club` into `data/`
- [x] 1.3 Confirm files present (accepted + rejected `.csv.gz`)
- [x] 1.4 Count rows — VERIFIED: accepted 2,260,701 (151 cols) · rejected 27,648,741 (9 cols)
- [x] 1.5 Inspect accepted: shape, columns, dtypes, memory ✓
- [x] 1.6 Inspect rejected file: confirmed exactly 9 columns

## Phase 2 — Data Understanding & Leakage Decision  _(interview Q1)_
- [x] 2.1 Reviewed columns against Lending Club data dictionary
- [x] 2.2 Identify target source (`loan_status`)
- [x] 2.3 Categorize columns: application-time vs post-origination
- [x] 2.4 Write `reports/leakage_exclusion_list.md` (column + reason)
- [x] 2.5 Decide on `grade` / `sub_grade` / `int_rate` (excluded — documented)
- [x] 2.6 Produce the allowed feature list (98 features → `reports/allowed_features.txt`)

## Phase 3 — Target Definition & Cohort Selection
- [x] 3.1 Define bad (`Charged Off`/`Default`) vs good (`Fully Paid`)
- [x] 3.2 Exclude `Current` / in-progress loans
- [x] 3.3 Matured-only handled via resolved-status filter
- [x] 3.4 Build binary target; class balance = 19.97% default
- [x] 3.5 Final cohort N = 1,345,350 (SQL `model_data` view)

> Dual track: every step exists in **pandas** (`notebooks/01_data_understanding.ipynb`)
> and **SQL/DuckDB** (`notebooks/01_data_understanding_sql.ipynb`, `sql/01_data_understanding.sql`,
> `data/credit.duckdb`). Numbers verified identical.

## Phase 4 — Feature Engineering & Preprocessing
- [ ] 4.1 Parse `issue_d` → vintage
- [ ] 4.2 Clean messy fields (`term`, `emp_length`, `revol_util`, `int_rate`, …)
- [ ] 4.3 Missing-value strategy
- [ ] 4.4 Encode categoricals
- [ ] 4.5 dtype optimization
- [ ] 4.6 Save processed modeling table

## Phase 5 — Out-of-Time Vintage Split  _(backs "out-of-time vintage validation")_
- [ ] 5.1 Choose cut date from `issue_d`
- [ ] 5.2 Train (older) / OOT test (newer)
- [ ] 5.3 In-time validation slice from train
- [ ] 5.4 Document split + row counts

## Phase 6 — Scorecard Baseline  _(backs "WoE/logistic scorecard baseline")_
- [ ] 6.1 WoE binning
- [ ] 6.2 Information Value (IV) feature selection
- [ ] 6.3 WoE transform
- [ ] 6.4 Logistic regression
- [ ] 6.5 Scale to points scorecard
- [ ] 6.6 Score: Gini / KS / Brier (in-time + OOT)

## Phase 7 — Monotonic XGBoost  _(backs "monotonic XGBoost")_
- [ ] 7.1 Set monotonic direction per feature
- [ ] 7.2 Train with `monotone_constraints`
- [ ] 7.3 Tune hyperparameters (on in-time validation)
- [ ] 7.4 Evaluate in-time vs OOT (report the gap plainly)
- [ ] 7.5 Compare vs scorecard baseline
- [ ] 7.6 Keep a prevented-monotonicity-violation example

## Phase 8 — Probability Calibration  _(backs "probability calibration (Gini/KS/Brier)")_
- [ ] 8.1 Reliability curve
- [ ] 8.2 Isotonic / Platt calibration
- [ ] 8.3 Brier before vs after
- [ ] 8.4 Lock final metrics table

## Phase 9 — SHAP Reason Codes  _(backs "SHAP reason codes")_
- [ ] 9.1 Global SHAP importance
- [ ] 9.2 Local SHAP per applicant
- [ ] 9.3 Convert to human reason codes (adverse-action style)
- [ ] 9.4 Save examples for README

## Phase 10 — Reject Inference ⚠️  _(backs "reject inference on 27M rejected")_
- [ ] 10.1 Map overlapping features (rejected file has only ~9 cols)
- [ ] 10.2 Score rejected with accepted-only model
- [ ] 10.3 Apply reject-inference method (framed as known-imperfect)
- [ ] 10.4 Retrain with inferred labels
- [ ] 10.5 Compare; discuss selection bias honestly
- [ ] 10.6 Write the caveat

## Phase 11 — PSI Drift Monitoring  _(backs "PSI drift monitoring")_
- [ ] 11.1 Reusable PSI function
- [ ] 11.2 Feature PSI + score PSI (train vs OOT)
- [ ] 11.3 Apply thresholds (0.1 / 0.25)
- [ ] 11.4 Tie drift back to OOT degradation

## Phase 12 — Serving: FastAPI + Docker  _(backs "(XGBoost, FastAPI, Docker)")_
- [ ] 12.1 Save artifacts (pipeline + model + calibrator)
- [ ] 12.2 FastAPI `/health` + `/predict` (PD + reason codes)
- [ ] 12.3 Pydantic input schema
- [ ] 12.4 Test locally with uvicorn
- [ ] 12.5 Dockerfile
- [ ] 12.6 Build image, run container, hit endpoint

## Phase 13 — Documentation & Repo Polish
- [ ] 13.1 README: results, plots, leakage list
- [ ] 13.2 Model card + limitations
- [ ] 13.3 Reproducibility instructions
- [ ] 13.4 Pin requirements versions
- [ ] 13.5 Add repo link to resume header + project line (only once demoable)
