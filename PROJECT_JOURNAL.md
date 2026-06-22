# Project Journal — Decisions, Trade-offs & Challenges

A narrative record of **what** we built, **why**, **how**, **why not the alternatives**, and the
**challenges** hit at each phase and how they were resolved. This is the interview-defense
companion to [PROJECT_PLAN.md](PROJECT_PLAN.md) (the forward checklist) and
[reports/leakage_exclusion_list.md](reports/leakage_exclusion_list.md).

Covers Phases 0–3 (data foundation) — complete and verified. Modeling phases will be appended as
they land.

---

## Key decisions at a glance

| Decision | Chose | Rejected | One-line reason |
|---|---|---|---|
| Dataset | `wordsforthewise/lending-club` (2007–2018Q4) | a 2007–2020Q3 accepted-only set | only this bundle has the **rejected** file + matches "2.2M" |
| Environment | `venv` + pip | Anaconda/conda | lightweight, portable, matches the Docker target |
| Git auth (2 accounts) | fine-grained PAT over HTTPS | SSH keys, browser OAuth | explicit per-repo control with two accounts |
| Notebook stack | `ipykernel` only | full `jupyter` metapackage | metapackage broke on Windows' 260-char path limit |
| SQL engine | DuckDB | SQLite, Postgres | runs SQL on `.csv.gz` directly; columnar; no server |
| LC `grade`/`int_rate` | **excluded** | keep as features | they're LC's own risk model — using them = parroting it |
| `Late`/`Current` loans | **excluded** from target | label them bad/good | outcome unresolved — labeling = guessing |
| Imbalance (20% default) | `scale_pos_weight` + calibration (planned) | SMOTE / resampling | imbalance is mild; resampling distorts probabilities |
| Data layer | **both** SQL + pandas | one or the other | mirrors real teams; cross-checks the numbers |

---

## Phase 0 — Environment & Repo Setup

**What.** Isolated `.venv`, folder skeleton (`data/ notebooks/ src/ models/ reports/`),
`requirements.txt`, `.gitignore`, `README.md`, `PROJECT_PLAN.md`; initialized git and pushed to a
public GitHub repo.

**Why.** A reproducible, isolated environment and a clean structure are the foundation of a
credible repo. The `.gitignore` keeps the ~600 MB of data and all secrets out of version control.

**How.** `python -m venv .venv` → activate → `pip install -r requirements.txt`; `git init` →
per-repo identity → commit → push with a fine-grained PAT.

**Why not the alternatives.**
- *Anaconda/conda instead of venv?* No — venv is lighter, portable, and matches what we'll put in
  the Docker image (Phase 12). Anaconda's base environment also had a broken NumPy, which a clean
  venv sidesteps entirely.
- *SSH or browser-OAuth for git?* The machine has **two** GitHub accounts. A fine-grained PAT
  scoped to just this repo, plus `credential.useHttpPath=true`, gives explicit control over which
  account pushes — no risk of committing as the wrong identity.
- *Private repo?* Public from the start (commit history shows real iteration), but the **resume
  line stays "in progress" until the repo is demoable** — build first, claim second.

**Challenges & resolutions.**
1. **`python -m loanvenv .venv` failed** — `-m` runs a *module*; `venv` is the module, the folder
   name is the argument. → `python -m venv .venv`.
2. **`Activate.ps1` blocked** — PowerShell's default execution policy. → `Set-ExecutionPolicy
   -Scope CurrentUser RemoteSigned`.
3. **Two GitHub accounts collided** — credential manager reuses one login per host. → per-repo
   identity (`git config user.email …` without `--global`) + `useHttpPath=true` + the right PAT.
4. **`pip install` crashed mid-way (Errno 2)** — the `jupyter` metapackage installs JupyterLab
   widget extensions whose path exceeds Windows' **260-char limit**. → dropped `jupyter`, kept
   `ipykernel` (all VS Code needs). Lesson logged: install into the venv via its explicit path
   `.\.venv\Scripts\python.exe -m pip …` so there's never ambiguity about the target environment.

---

## Phase 1 — Data Acquisition & Verification

**What.** Downloaded the Lending Club data and **verified the resume's headline numbers**:
accepted = **2,260,701** rows (151 cols), rejected = **27,648,741** rows (9 cols).

**Why.** These two numbers are the most falsifiable claims on the resume — an interviewer can
check them by loading the file. Counting also confirms the download isn't truncated and sizes the
memory job.

**How.** Kaggle website download → unzip → keep the two `.csv.gz` files. Row counts done
memory-safely by reading **one column in chunks** (never the whole 27 M × 9 table at once).

**Why not the alternatives.**
- *The first dataset downloaded* was `Loan_status_2007-2020Q3` — **accepted-only, 2.93 M rows, no
  rejected file**. Rejected → re-downloaded `wordsforthewise/lending-club`, the only public bundle
  with **both** accepted and rejected, which (a) is required for reject inference and (b) matches
  "2.2M" (the 2020Q3 set was 2.93 M).
- *Why 2018Q4 not 2020Q3?* A PD model needs **matured** loans, not recent ones; 2018Q4 is more
  seasoned, and its ~2.26 M matches the resume.
- *Kaggle CLI/token vs website?* Website — one-time, simpler, and avoids handling a live token.
- *Keep the uncompressed CSVs?* No — the zip shipped each file twice; we extracted only the small
  `.csv.gz` (pandas/DuckDB read them directly), saving ~3.4 GB.

**Challenges & resolutions.**
1. **Wrong dataset** (accepted-only) — caught by *inspecting before trusting*; re-downloaded the
   correct one.
2. **Live Kaggle token pasted into chat** — flagged as a secret; advised revoke + regenerate, and
   added `kaggle.json` to `.gitignore`.
3. **A file misnamed `.gzip` was actually plain CSV** — DuckDB/pandas error on bad magic bytes; read
   it without gzip. (Reinforced: verify file *type*, not just extension.)
4. **Counting 27 M rows on 16 GB RAM** — chunked, single-column read keeps memory flat.

---

## Phase 2 — Data Understanding & the Leakage Exclusion List

**What.** Categorized all 151 accepted columns and produced
[reports/leakage_exclusion_list.md](reports/leakage_exclusion_list.md): **53 columns excluded →
98 allowed features**.

**Why.** Leakage is the single thing that separates a real credit model from a fake-99%-AUC
notebook, and *"which columns did you exclude and why"* is interview question #1.

**How — the decision-point test.** A PD model scores an application **the moment it arrives**, so a
column is only legal if it exists at that instant. Everything populated *after* origination is
banned. The 53 fall into clear buckets: post-origination **payment/performance** (`total_pymnt`,
`recoveries`, `last_fico_*`, …), **hardship**, **settlement**, plus **identifiers/constants** and
LC's **own pricing**.

**Why not the alternatives.**
- *Keep `grade`/`sub_grade`/`int_rate`?* They're known at application (not leakage) but they **are
  Lending Club's own risk verdict** — using them means re-predicting LC's model. Excluded so the
  model finds risk independently; `grade` can later serve as a *benchmark to beat*. `installment`
  also dropped because it's derived from `int_rate` and would smuggle it back in.
- *Keep `last_fico_range_*`?* No — that's FICO **re-pulled during the loan**; only the
  application-time `fico_range_*` is allowed. (One word — `last_` — separates legal from leakage.)
- *Keep `emp_title`/`desc` free text?* Dropped for the baseline (high-cardinality, messy); a later
  NLP pass could revisit `emp_title`.

**Challenges & resolutions.**
- The leaky set is large and some members are **subtle** (`installment` ← `int_rate`; `last_fico`
  vs `fico`; hardship/settlement fields that only exist *if the loan went bad*). → reasoned every
  column against the decision-point test and documented each in the exclusion list, so the choices
  are defensible rather than ad-hoc.

---

## Phase 3 — Target Definition & Cohort Selection

**What.** Binary target from `loan_status`: **`Charged Off`/`Default` = 1**, **`Fully Paid` = 0**;
excluded in-progress, off-policy, and junk rows. Final cohort = **1,345,350** loans, **19.97%**
default rate.

**Why.** A PD label must be a **resolved** outcome — you can only call a loan good or bad once it's
finished. Keeping only resolved statuses *also* solves loan maturity for free (immature loans are
all `Current`).

**How.** `value_counts(loan_status)` → map resolved statuses, drop the rest.

**Why not the alternatives.**
- *Label `Late (31–120)` as bad?* No — unresolved; some recover. Labeling it would be guessing and
  reads as junior.
- *Keep "Does not meet the credit policy" loans?* Excluded — they were funded under LC's *old,
  looser* policy; mixing underwriting regimes muddies the population.
- *Fix the 20% imbalance with SMOTE/oversampling?* No — 1-in-5 is mild, and synthetic resampling
  distorts the very probabilities we need to **calibrate**. We'll use `scale_pos_weight` + proper
  calibration instead.

**Challenges & resolutions.**
- **33 junk rows** (Lending Club summary lines like *"Total amount funded in policy code 1: …"*)
  surfaced as a mixed-type `id` warning. → identified via `loan_amnt IS NULL`; they're naturally
  excluded by the resolved-status target filter.
- **Honest framing of "2.2M":** the dataset is 2.26 M, but the *modeling cohort* is 1.35 M after
  dropping unresolved/off-policy loans. Documented so the resume number and the training set are
  reconcilable on demand.

---

## Cross-cutting: the SQL / DuckDB track

**What.** Re-implemented the entire data layer in SQL: `data/credit.duckdb` with `accepted` /
`rejected` tables and `accepted_features` / `model_data` views, plus a runnable SQL notebook and a
standalone `.sql` file. Every number matches pandas exactly.

**Why.** Real data teams do heavy wrangling in SQL and modeling in Python; having both (cross-checked)
is an honest, strong signal — and it backs SQL on the resume.

**Why not.** *SQLite?* needs a separate load step and is weaker for analytics. *Postgres?* a server
is overkill. **DuckDB** runs standard SQL directly on the `.csv.gz`, is columnar/fast, and is
embedded.

**Challenges & resolutions.**
1. **Junk rows broke type detection** — DuckDB auto-typed `id` as `BIGINT` from a small sample,
   then hit a text summary row. → `sample_size=-1` (scan the whole file for type inference).
2. **`desc` is a reserved word** and rejected columns have **spaces** (`"Policy Code"`). → quote
   every identifier in SQL.

---

## Consolidated challenges log (quick reference)

| # | Challenge | Root cause | Fix |
|---|---|---|---|
| 1 | venv creation failed | `-m loanvenv` (module vs folder) | `python -m venv .venv` |
| 2 | `Activate.ps1` blocked | PS execution policy | `Set-ExecutionPolicy CurrentUser RemoteSigned` |
| 3 | wrong-account git push risk | one credential per host | per-repo identity + `useHttpPath` + PAT |
| 4 | `pip install` crash | `jupyter` extension > 260-char path | drop `jupyter`, keep `ipykernel` |
| 5 | "pandas not found" in venv | install hit the long-path crash (incomplete) | install via `.\.venv\Scripts\python.exe` |
| 6 | wrong dataset (no rejected) | grabbed a 2020Q3 accepted-only set | re-download `wordsforthewise/lending-club` |
| 7 | counting 27 M rows on 16 GB | full load too big | chunked single-column read |
| 8 | DuckDB type error | junk rows + small sample | `sample_size=-1` |
| 9 | DuckDB parser error | `desc` reserved / spaced names | quote identifiers |
| 10 | base-env NumPy 1.x/2.x clash | Anaconda base | use the isolated `.venv` |

---

## Current status

Data foundation **done and verified**: 2.26 M accepted / 27.6 M rejected, 98 leakage-safe
features, 1.35 M-loan modeling cohort at 19.97% default — implemented in **pandas and SQL** with
identical results. Next: out-of-time vintage split → scorecard baseline → monotonic XGBoost.

---

## Likely interview questions & answers

**Q. Which columns did you exclude, and why?**
53 of 151. The bulk are *post-origination* fields — payment/performance (`total_pymnt`,
`recoveries`, `out_prncp`, `last_fico_*`), hardship, and settlement — which only exist *after* the
loan is funded, so they encode the outcome. Plus identifiers/constants, and Lending Club's own
pricing (`grade`, `int_rate`, `installment`). The test for each: *would this value exist the
moment the application arrives?*

**Q. Give a concrete leakage example.**
`total_rec_prncp` (principal received) ≈ the loan amount for fully-paid loans and far less for
charged-off ones — it's the outcome restated. Leave it in and you get ~0.99 AUC that collapses on
real applicants, because you'd never have that value at decision time.

**Q. Why exclude `grade`/`int_rate` if they're known at application?**
They're not leakage — they're *Lending Club's own risk verdict*. Using them means re-predicting
LC's model instead of finding risk in borrower fundamentals. Excluding them yields an independent
model and lets LC's `grade` serve as a benchmark to beat.

**Q. Why an out-of-time split instead of a random one?**
Credit models are deployed *forward in time*. A random split leaks future vintages into training
and inflates metrics. Training on older vintages and testing on newer ones (OOT) measures what
actually matters: does the model hold up on loans it hasn't seen the era of?

**Q. The resume says 2.2 M but you model on 1.35 M — explain.**
2.26 M is the dataset; 1.35 M is the *resolved* cohort after dropping in-progress (`Current`,
`Late`), off-policy, and junk rows. You can only label a loan good/bad once it's finished.

**Q. Is the data imbalanced? How will you handle it?**
19.97% default — mild. I'll use `scale_pos_weight` in XGBoost plus probability calibration, not
SMOTE — synthetic oversampling distorts the very probabilities a PD model must get right.

**Q. Reject inference on 27 M rows — what could you actually do?**
The rejected file has only 9 columns, so inference is limited to the ~5 features shared with the
accepted set (amount, DTI, employment length, a FICO-like risk score, geography). I treat it as a
known-imperfect method and discuss selection bias openly rather than overselling it.

**Q. How will you know the model is any good?**
Gini/KS/Brier reported **in-time vs OOT** (and the gap stated plainly), calibration/reliability
curves, and PSI to confirm the OOT population hasn't drifted beyond what the metrics assume.

**Q. Why DuckDB / why a SQL track at all?**
Real teams wrangle in SQL and model in Python. DuckDB runs standard SQL directly on the `.csv.gz`,
is columnar/fast, and needs no server — so the data layer is reproducible in SQL and cross-checked
against pandas.

---

## Glossary

| Term | Meaning |
|---|---|
| **PD** | Probability of Default — the model's output |
| **Default / "bad"** | Here: `Charged Off` or `Default` status |
| **WoE** | Weight of Evidence — log-odds transform of a binned feature (scorecard input) |
| **IV** | Information Value — a WoE-based measure of a feature's predictive strength |
| **Gini / AUC** | Rank-ordering power; Gini = 2·AUC − 1 |
| **KS** | Kolmogorov–Smirnov — max separation between good/bad score distributions |
| **Brier** | Mean squared error of predicted probabilities (lower = better calibrated) |
| **Calibration** | Making predicted probabilities match observed frequencies |
| **OOT / vintage** | Out-of-time; a vintage = loans grouped by issue period |
| **PSI** | Population Stability Index — distribution shift (drift) measure |
| **Reject inference** | Estimating performance for never-approved applicants (selection-bias fix) |
| **Monotonic constraint** | Forcing the model's response to move one direction in a feature |
| **Scorecard** | Points-based logistic model, the regulatory-standard baseline |
| **`scale_pos_weight`** | XGBoost knob to up-weight the minority (default) class |
| **Reason codes** | Per-applicant "why declined" explanations (adverse-action style) |

---

## Known limitations & what I'd do differently

- **Reject inference is inherently weak here** — only ~5 features overlap the accepted set, so any
  inferred labels are uncertain. It's a defensible *demonstration* of the technique, not a strong
  correction; framed openly as such.
- **Data vintage is 2007–2018** — this proves *methodology*, not current-market prediction. The
  techniques transfer; the coefficients wouldn't.
- **Excluding `grade`/`int_rate` is a deliberate stance** — some lenders keep them. I chose
  independence + benchmarking; I'd revisit if the goal were pure predictive lift.
- **No macroeconomic features** (unemployment, rate environment) — a production PD model would add
  them; they materially affect default cycles.
- **Geography underused** — `zip_code`/`addr_state` are kept but not enriched with external data.
- **Single train/OOT split** — multiple rolling OOT windows would test temporal robustness harder.
- **Free-text dropped** — `emp_title`/`desc` are excluded from the baseline; an NLP pass could
  extract signal later.
