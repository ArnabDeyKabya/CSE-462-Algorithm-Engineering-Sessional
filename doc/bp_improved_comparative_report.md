# Improved Branch-and-Price (Branch-and-Bound style finalize): Context and Comparison Workflow

## What was requested

Replicate the same baseline vs improved project structure used for ILS, but for Branch-and-Bound/Branch-and-Price as well.

## What is now in the project

Baseline B&P:
- `top_branch_price.py`
- `run_experiment_bp.ps1`
- Output root: `output_bp`

Improved B&P:
- `top_branch_price_improved.py`
- `run_experiment_bp_improved.ps1`
- Output root: `output_bp_improved`

B&P comparison:
- `compare_bp_results.py`
- Comparison output root: `output_bp_comparison`

## Improved B&P strategy implemented

`top_branch_price_improved.py` keeps the same core pipeline but adds a robust improvement layer:

1. Multi-start diversification per run
- For each run, execute baseline B&P multiple times (`--restarts`, default 3)
- Use diversified seeds (`--seed-jump`, default 97)
- Keep the best-scoring solution

2. Stronger default search effort
- Higher default CG and pricing effort than baseline:
  - `--max-cg-iterations 12`
  - `--pricing-trials 22`
  - `--max-insertions 18`
- Baseline defaults are lower and faster.

3. Resume-safe experiment behavior
- Same `--skip-existing` behavior pattern
- Compatible with interrupted long runs

4. Reproducibility metadata
- Writes improved-specific config into `metrics_overview.json`:
  - `improved_restarts`
  - `improved_seed_jump`

## How to run

Baseline B&P full experiment:

```powershell
./run_experiment_bp.ps1
```

Improved B&P full experiment:

```powershell
./run_experiment_bp_improved.ps1
```

B&P baseline vs improved comparison:

```powershell
python compare_bp_results.py
```

## Comparison outputs

`compare_bp_results.py` produces:

- `output_bp_comparison/dataset_comparison.csv`
- `output_bp_comparison/instance_comparison.csv`
- `output_bp_comparison/quick_delta_table.csv`
- `output_bp_comparison/figures/dataset_mean_cpu_comparison.png`
- `output_bp_comparison/figures/dataset_mean_gap_comparison.png`
- `output_bp_comparison/figures/dataset_success_rate_comparison.png`
- `output_bp_comparison/figures/instance_score_scatter.png`
- `output_bp_comparison/figures/runtime_vs_size_overlay.png`

## Expected trade-off

As with improved ILS, improved B&P is expected to trade additional runtime for better solution quality/stability due to multi-start diversification and stronger pricing effort.
