# Project Plan & Progress Tracker

Phase-by-phase build plan for the Credit Risk PD Engine. Check off substeps as we complete
them. Each phase maps to a specific phrase on the resume line it backs.

Legend: `[ ]` todo · `[~]` in progress · `[x]` done

---

## Phase 0 — Environment & Repo Setup
- [x] 0.1 Create virtual environment (`.venv`)
- [~] 0.2 Activate venv
- [x] 0.3 Folder structure (`data/ notebooks/ src/ models/ reports/`)
- [x] 0.4 `requirements.txt`
- [x] 0.5 `.gitignore`
- [ ] 0.6 `pip install -r requirements.txt`
- [ ] 0.7 git identity + first commit + push to GitHub

## Phase 1 — Data Acquisition & Verification  _(backs "2.2M loans" + "27M rejected")_
- [ ] 1.1 Kaggle token / download
- [ ] 1.2 Download `wordsforthewise/lending-club` into `data/`
- [ ] 1.3 Confirm files present (accepted + rejected, likely `.csv.gz`)
- [ ] 1.4 Count rows of both files — verify ~2.26M / ~27M
- [ ] 1.5 Inspect accepted file: shape, columns, dtypes, memory
- [ ] 1.6 Inspect rejected file: note its ~9 columns

## Phase 2 — Data Understanding & Leakage Decision  _(interview Q1)_
- [ ] 2.1 Read the Lending Club data dictionary
- [ ] 2.2 Identify target source (`loan_status`)
- [ ] 2.3 Categorize columns: application-time vs post-origination
- [ ] 2.4 Write `reports/leakage_exclusion_list.md` (column + reason)
- [ ] 2.5 Decide on `grade` / `sub_grade` / `int_rate` (document it)
- [ ] 2.6 Produce the allowed feature list

## Phase 3 — Target Definition & Cohort Selection
- [ ] 3.1 Define bad (`Charged Off`/`Default`) vs good (`Fully Paid`)
- [ ] 3.2 Exclude `Current` / in-progress loans
- [ ] 3.3 Keep only matured/seasoned vintages
- [ ] 3.4 Build binary target; check class balance
- [ ] 3.5 Document final cohort N

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
