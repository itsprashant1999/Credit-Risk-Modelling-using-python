# Credit Risk PD Engine

A probability-of-default (PD) model built on real Lending Club consumer-loan data, engineered
with the discipline a bank's model-risk function would actually require: strict data-leakage
control, out-of-time validation, a regulatory-style scorecard baseline, monotonic gradient
boosting, probability calibration, explainability (SHAP reason codes), drift monitoring (PSI),
reject inference, and a containerized serving API. The data layer is implemented in **both
SQL (DuckDB) and Python/pandas**, with identical, cross-checked results.

> **Status: 🚧 In active development.** The data foundation (data understanding, leakage control,
> target definition) is **complete and verified**; modeling, calibration, explainability, reject
> inference, and serving are in progress. See **[PROJECT_PLAN.md](PROJECT_PLAN.md)** for the
> phase-by-phase tracker and **[PROJECT_JOURNAL.md](PROJECT_JOURNAL.md)** for the decisions,
> trade-offs & challenges log.

---

## The problem

Given an applicant's information **as known at the moment of application**, estimate the
probability that the loan will default. The emphasis is *not* on chasing a headline AUC, but on
building a model that would survive model-risk review: honest validation, calibrated
probabilities, explainable decisions, and monitored drift.

## Dataset

- **Source:** Lending Club accepted & rejected loans (2007–2018Q4), via Kaggle —
  [`wordsforthewise/lending-club`](https://www.kaggle.com/datasets/wordsforthewise/lending-club)
- **Accepted loans:** **2,260,701** rows (verified) — the modeling population
- **Rejected applications:** **27,648,741** rows (verified) — used for reject inference
- **Why this dataset:** it is the standard public credit dataset with *real default outcomes*,
  loan-issue timestamps that enable out-of-time validation, and — rarely — a companion file of
  *rejected* applications, which is what makes a genuine reject-inference exercise possible.

> ⚠️ **The raw data is not included in this repo** (large + licensed). Download it from the
> Kaggle link above and place the two `.csv.gz` files in `data/`. See [Setup](#setup).

### Leakage discipline
A core deliverable is an explicit **leakage exclusion list** — every column populated *after*
loan origination (repayment history, recoveries, post-origination FICO, hardship/settlement
flags, …) is banned, because it would not exist when scoring a new applicant. See
**[reports/leakage_exclusion_list.md](reports/leakage_exclusion_list.md)**: **53 columns excluded**
(post-origination payment, hardship, settlement, plus Lending Club's own `grade`/`int_rate`
pricing), leaving the **98 allowed features** in `reports/allowed_features.txt`.

## What's built so far (verified)

| Step | Result |
|---|---|
| Accepted / rejected rows | 2,260,701 / 27,648,741 |
| Leakage-safe features | **98** of 151 |
| Target | `Charged Off`/`Default` = 1, `Fully Paid` = 0; in-progress & off-policy excluded |
| Modeling cohort | **1,345,350** resolved loans |
| Default rate | **19.97%** |

Implemented twice and cross-checked to identical numbers:
- **pandas** → [notebooks/01_data_understanding.ipynb](notebooks/01_data_understanding.ipynb)
- **SQL / DuckDB** → [notebooks/01_data_understanding_sql.ipynb](notebooks/01_data_understanding_sql.ipynb)
  + [sql/01_data_understanding.sql](sql/01_data_understanding.sql) (builds `data/credit.duckdb`
  with `accepted_features` and `model_data` views)

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
├── data/         # raw CSVs + credit.duckdb (gitignored — download from Kaggle)
├── notebooks/    # 01_data_understanding.ipynb (pandas) + _sql.ipynb (DuckDB)
├── sql/          # standalone SQL — 01_data_understanding.sql
├── src/          # reusable modules (features, model, scoring, API) — coming
├── models/       # saved artifacts (gitignored)
├── reports/      # leakage_exclusion_list.md, allowed_features.txt, metrics, plots
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

# 3. data — download from Kaggle, place the two .csv.gz files in data/
#    https://www.kaggle.com/datasets/wordsforthewise/lending-club
```

> Running the notebooks: open in VS Code / Cursor and select the **`.venv`** kernel. The SQL
> notebook auto-builds `data/credit.duckdb` from the CSVs on first run.

## Results

_Filled in as modeling phases complete._

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
