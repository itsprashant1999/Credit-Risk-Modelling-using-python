# Credit Risk PD Engine

A probability-of-default (PD) model built on real Lending Club consumer-loan data, engineered
with the discipline a bank's model-risk function would actually require: strict data-leakage
control, out-of-time validation, a regulatory-style scorecard baseline, monotonic gradient
boosting, probability calibration, explainability (SHAP reason codes), drift monitoring (PSI),
reject inference, and a containerized serving API.

> **Status: 🚧 In active development.** This README documents the *target* design. Sections
> marked _planned_ or _tbd_ are not built yet; results tables are filled in as each phase
> completes. See **[PROJECT_PLAN.md](PROJECT_PLAN.md)** for the phase-by-phase tracker.

---

## The problem

Given an applicant's information **as known at the moment of application**, estimate the
probability that the loan will default. The emphasis is *not* on chasing a headline AUC, but on
building a model that would survive model-risk review: honest validation, calibrated
probabilities, explainable decisions, and monitored drift.

## Dataset

- **Source:** Lending Club accepted & rejected loans (2007–2018Q4), via Kaggle —
  [`wordsforthewise/lending-club`](https://www.kaggle.com/datasets/wordsforthewise/lending-club)
- **Accepted loans:** ~2.26M rows (the modeling population)
- **Rejected applications:** ~27M rows (used for reject inference)
- **Why this dataset:** it is the standard public credit dataset with *real default outcomes*,
  loan-issue timestamps that enable out-of-time validation, and — rarely — a companion file of
  *rejected* applications, which is what makes a genuine reject-inference exercise possible.

> ⚠️ **The raw data is not included in this repo** (large + licensed). Download it from the
> Kaggle link above and place the files in `data/`. See [Setup](#setup).

### Leakage discipline
A core deliverable is an explicit **leakage exclusion list** — every column populated *after*
loan origination (repayment history, recoveries, post-origination FICO, hardship/settlement
flags, etc.) is banned from the feature set, because it would not exist when scoring a new
applicant. The documented list will live in `reports/leakage_exclusion_list.md` _(planned)_.

## Methodology

| Stage | Approach |
|---|---|
| Target | `Charged Off` / `Default` = bad, `Fully Paid` = good; immature / in-progress loans excluded |
| Validation | **Out-of-time vintage split** — train on older issue vintages, test on newer (never a random split) |
| Baseline | **WoE + logistic-regression scorecard** (regulatory-standard benchmark) |
| Main model | **Monotonic XGBoost** — monotonic constraints encode business logic |
| Metrics | **Gini / KS / Brier**, reported in-time vs out-of-time |
| Calibration | Reliability curves + isotonic / Platt scaling |
| Explainability | **SHAP** global importance + per-applicant reason codes |
| Reject inference | Inferred performance for rejected applicants (known-imperfect; selection bias discussed openly) |
| Monitoring | **PSI** drift on features and scores |
| Serving | **FastAPI** `/predict` endpoint, **Docker** container |

## Project structure

```
.
├── data/         # raw Lending Club CSVs (gitignored — download from Kaggle)
├── notebooks/    # exploration & per-phase analysis
├── src/          # reusable modules (features, model, scoring, API)
├── models/       # saved artifacts (gitignored)
├── reports/      # metrics, plots, leakage list, model card
├── requirements.txt
└── PROJECT_PLAN.md
```

## Setup

```powershell
# 1. clone
git clone https://github.com/itsprashant1999/Credit-Risk-Modelling-using-python.git
cd Credit-Risk-Modelling-using-python

# 2. environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1          # Windows PowerShell
pip install -r requirements.txt

# 3. data — download from Kaggle, place the two files in data/
#    https://www.kaggle.com/datasets/wordsforthewise/lending-club
```

## Results

_Filled in as phases complete._

| Model | Split | Gini | KS | Brier |
|---|---|---|---|---|
| Scorecard (WoE + LR) | in-time | _tbd_ | _tbd_ | _tbd_ |
| Scorecard (WoE + LR) | OOT | _tbd_ | _tbd_ | _tbd_ |
| Monotonic XGBoost | in-time | _tbd_ | _tbd_ | _tbd_ |
| Monotonic XGBoost | OOT | _tbd_ | _tbd_ | _tbd_ |

## Limitations

_Model card and honest limitations (including reject-inference caveats) to be added as the
project matures._

## License

Educational / portfolio use. Lending Club data is subject to its own terms.
