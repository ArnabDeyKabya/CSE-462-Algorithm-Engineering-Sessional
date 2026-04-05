# Improved ILS Run: Fixes and Comparative Results

## What Was Fixed

The improved pipeline had two practical issues during long runs:

1. It looked "stuck" because there was no live progress output.
2. Interrupted runs did not resume cleanly, so only part of `output_improved/instances` could appear.

These were fixed in `top_ils_improved.py` and a dedicated runner was added.

## Engineering Fixes Applied

### 1. Guaranteed per-dataset output folders

At experiment start, the code now always creates:

- `output_improved/instances/chao`
- `output_improved/instances/dang`
- `output_improved/instances/vansteenwegen`

So folder structure is always consistent even before all runs finish.

### 2. Resume mode with skip-existing

A new experiment option was added:

- `--skip-existing`

Behavior:

- If `instance__runXX.json` already exists, the run is skipped.
- Missing runs are computed.
- This allows safe resume after interruption without redoing completed work.

### 3. Idempotent metric rebuild from JSON outputs

After runs finish, metrics are rebuilt by scanning all existing per-run JSON files in `output_improved/instances/*`.

This guarantees:

- `summary.csv`, `instance_metrics.csv`, and `dataset_metrics.csv` reflect the full available outputs
- Resume runs produce consistent aggregate metrics

### 4. Progress logging to avoid “stuck” perception

The experiment now prints dataset and run progress:

- `[dataset] chao: 240 instances`
- `[run] chao/p4.3.b.txt run=0 (22/240)`

So you can see that it is actively processing.

### 5. Local-search guard for large instances

To avoid heavy slowdowns:

- Inter-route relocate/swap is enabled only for moderate-size instances (`<= 180` customers)
- Local search has a capped number of rounds (`max_rounds`)

This keeps improved runs stable on larger benchmark sets.

### 6. Dedicated improved runner script

Added:

- `run_experiment_improved.ps1`

It runs:

- dataset preparation
- improved ILS experiment
- output to `output_improved`
- resume mode enabled

## Current Output Structure (Verified)

All dataset folders exist under `output_improved/instances`:

- `chao`
- `dang`
- `vansteenwegen`

Per-run JSON counts:

- Chao: 480
- Dang: 164
- Vansteenwegen: 134

(2 runs per instance.)

## Baseline vs Improved: Dataset-Level Comparison

Source files:

- Baseline: `output/dataset_metrics.csv`
- Improved: `output_improved/dataset_metrics.csv`

### Chao

- Mean CPU time: 0.1505 -> 0.2252 s
- Mean gap (%): 1.1192 -> 1.1019 (slight improvement)
- Success rate (%): 66.04 -> 66.67 (slight improvement)
- Score mean: 635.40 -> 635.29 (very close)

Interpretation:

- Quality improves slightly; runtime increases modestly due to stronger search steps.

### Dang

- Mean CPU time: 3.6324 -> 2.6492 s (faster)
- Mean gap (%): 1.9077 -> 2.0438 (slightly worse)
- Success rate (%): 53.66 -> 52.44 (slightly worse)
- Score mean: 3898.96 -> 3834.72 (lower)

Interpretation:

- Runtime improved significantly, but quality dipped on this set.
- The large-instance guard likely reduced expensive inter-route improvements, trading quality for speed.

### Vansteenwegen

- Mean CPU time: 2.4111 -> 1.6145 s (faster)
- Mean gap (%): 1.9435 -> 2.2446 (worse)
- Success rate (%): 54.48 -> 52.24 (slightly worse)
- Score mean: 3498.57 -> 3444.53 (lower)

Interpretation:

- Similar tradeoff as Dang: higher throughput, slightly weaker average quality.

## Why These Strategies Can Still Help

The applied strategies are designed for robustness and completion reliability:

- Resume and skip-existing enable large benchmark campaigns to finish reliably.
- Progress logs provide observability during long runs.
- Search guards prevent pathological slowdown on large instances.

Algorithmically, inter-route moves and adaptive perturbation can improve quality, but the current guard/tuning favors stability and speed.

## Practical Next Tuning for Better Quality

To improve result quality further while keeping reliability:

1. Increase iterations for improved runs (for example 30-60).
2. Keep `--skip-existing` and rerun only missing/new runs.
3. Re-enable inter-route moves for larger instances conditionally when stagnation is high.
4. Tune acceptance temperature and adaptive remove fraction by dataset.
5. Increase runs-per-instance (for example 5) for a stronger reference-best estimate.

## Files Added/Updated in This Fix

- `top_ils_improved.py` (resume/progress/stability fixes)
- `run_experiment_improved.ps1` (dedicated improved experiment runner)
- `doc/ils_improved_comparative_report.md` (this report)
