# Branch-and-Price for TOP: Step-by-Step Plan and Implementation

## Goal

Implement a Branch-and-Price style pipeline for Team Orienteering Problem (TOP) using the same datasets already used for ILS, with complete experiment outputs and metrics.

## Step-by-Step Plan

1. Reuse the same dataset structure
- Use `datasets/chao`, `datasets/dang`, `datasets/vansteenwegen`.
- Keep identical instance parser and experiment conventions.

2. Implement TOP data and parsing layer
- Parse benchmark files (`n`, `m`, `tmax`, node rows).
- Auto-detect depots using zero-score nodes when present.

3. Implement route-column representation
- Define route columns with:
  - node sequence
  - visited customer set
  - route score
  - route length

4. Implement initial Restricted Master Problem (RMP) columns
- Add empty route columns.
- Add single-customer feasible routes.
- Add a subset of feasible two-customer routes.

5. Implement RMP solver (LP and integer)
- Solve LP RMP for column generation.
- Extract dual prices for customer constraints and vehicle constraint.
- Solve integer master over generated columns as final branch-and-price style step.

6. Implement pricing subproblem (practical heuristic pricing)
- Build routes using reduced profits:
  - modified score = `p_i - pi_i`
- Use randomized insertion heuristic under distance budget.
- Generate positive reduced-profit columns.
- Track labels generated metric.

7. Implement root column generation loop
- Iterate:
  - solve LP RMP
  - run pricing
  - add improving columns
- Stop when no improving columns or max CG iterations reached.

8. Build full experiment pipeline on same datasets
- Per-run JSON output under per-dataset folders.
- Resume-safe behavior (`--skip-existing`).
- Rebuild summary/aggregates from generated JSONs.

9. Generate all metrics outputs
- `summary.csv`
- `instance_metrics.csv`
- `dataset_metrics.csv`
- `quality_distribution.csv`
- `runtime_vs_instance_size.csv`
- `runtime_vs_instance_size.png`
- `metrics_overview.json`

10. Validate and fix runtime/robustness issues
- Add progress logging.
- Resume long runs safely.
- Fix edge-case numeric failure (`None` objective from LP solver).

## What Was Implemented

### New Solver and Experiment Engine

- `top_branch_price.py`

Contains:
- TOP parsing
- Route column modeling
- LP RMP with dual extraction
- Heuristic pricing subproblem
- Root column generation
- Integer master solve
- Full metrics and output generation

### New Runner Script

- `run_experiment_bp.ps1`

Runs:
- dataset preparation
- Branch-and-Price experiments on same datasets
- output into `output_bp`

## Execution Status

Full experiment completed on same datasets.

Dataset counts verified:
- Chao: 240 instances
- Dang: 82 instances
- Vansteenwegen: 67 instances

Total: 389 instances

Run count in this B&P setup:
- 1 run per instance (389 runs)

All runs successful (`err = 0`) in `output_bp/summary.csv`.

## Output Locations

- `output_bp/summary.csv`
- `output_bp/instance_metrics.csv`
- `output_bp/dataset_metrics.csv`
- `output_bp/quality_distribution.csv`
- `output_bp/runtime_vs_instance_size.csv`
- `output_bp/runtime_vs_instance_size.png`
- `output_bp/metrics_overview.json`
- `output_bp/instances/chao/*.json`
- `output_bp/instances/dang/*.json`
- `output_bp/instances/vansteenwegen/*.json`

## Notes on Branch-and-Price Interpretation

This implementation is a practical Branch-and-Price style pipeline:
- LP column generation at root node
- heuristic pricing using reduced profits
- final integer master solve over generated columns

It is suitable for experimental benchmarking and metric collection across large benchmark sets in this project context.
