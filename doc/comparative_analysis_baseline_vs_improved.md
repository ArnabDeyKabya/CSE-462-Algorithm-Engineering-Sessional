# Comparative Analysis: Baseline vs Improved ILS

## Scope

This report compares the baseline experiment outputs in `output` with the improved experiment outputs in `output_improved` on the same datasets and metric framework.

Generated comparison artifacts are in:

- `output_comparison/dataset_comparison.csv`
- `output_comparison/instance_comparison.csv`
- `output_comparison/quick_delta_table.csv`
- `output_comparison/figures/*`

## Visualization Set Generated

The following comparison plots were generated:

1. `output_comparison/figures/dataset_mean_cpu_comparison.png`
2. `output_comparison/figures/dataset_mean_gap_comparison.png`
3. `output_comparison/figures/dataset_success_rate_comparison.png`
4. `output_comparison/figures/instance_score_scatter.png`
5. `output_comparison/figures/instance_runtime_scatter.png`
6. `output_comparison/figures/runtime_vs_size_overlay.png`
7. `output_comparison/figures/baseline_gap_distribution.png`
8. `output_comparison/figures/improved_gap_distribution.png`

These jointly cover dataset-level, instance-level, distributional, and scaling behavior.

## Dataset-Level Quantitative Comparison

From `output_comparison/dataset_comparison.csv`:

### Chao

- Mean CPU time: +49.60% (slower)
- Mean gap: -1.54% (slightly better)
- Success rate: +0.95% (slightly better)
- Mean score: -0.02% (nearly unchanged)
- Mean iterations to convergence: -6.63% (faster convergence)

### Dang

- Mean CPU time: -27.07% (faster)
- Mean gap: +7.14% (worse)
- Success rate: -2.27% (worse)
- Mean score: -1.65% (worse)
- Mean iterations to convergence: -2.71% (slightly faster)

### Vansteenwegen

- Mean CPU time: -33.04% (faster)
- Mean gap: +15.49% (worse)
- Success rate: -4.11% (worse)
- Mean score: -1.54% (worse)
- Mean iterations to convergence: -4.59% (faster)

## Visual Interpretation

### 1. CPU comparison

From `dataset_mean_cpu_comparison.png` and `runtime_vs_size_overlay.png`:

- Improved strategy reduced runtime substantially on Dang and Vansteenwegen.
- Chao runtime increased moderately.

### 2. Gap and success-rate comparison

From `dataset_mean_gap_comparison.png` and `dataset_success_rate_comparison.png`:

- Chao gained a slight quality improvement.
- Dang and Vansteenwegen show a quality drop under current improved settings.

### 3. Instance-level effects

From `instance_score_scatter.png` and `instance_runtime_scatter.png`:

- Runtime scatter lies more often below diagonal for medium/large instances (faster improved).
- Score scatter has many points near diagonal but with a downward bias on Dang/Vansteenwegen.

### 4. Distribution-level behavior

From `baseline_gap_distribution.png` and `improved_gap_distribution.png`:

- Improved run retains many zero-gap hits but shows a slightly heavier upper tail in some sets.
- This indicates stronger variability tradeoff under current tuning.

## Why This Happened

The improved solver includes stronger engineering controls:

- Resume-friendly skip-existing processing
- Bounded local search rounds
- Inter-route heavy moves restricted for larger instances

These changes improve completion stability and throughput, but can reduce exploration intensity for large instances, causing a small quality drop on Dang/Vansteenwegen.

## Practical Conclusion

Current improved configuration is better when priority is:

- robustness on long experiment campaigns
- faster completion on medium/large datasets

Baseline remains better when priority is:

- maximizing mean score and success rate on Dang/Vansteenwegen under the same low iteration budget

## Recommended Next Step for a Better Improved Variant

To retain improved robustness while regaining quality:

1. Increase iterations for improved runs on large instances.
2. Enable inter-route moves adaptively during stagnation (instead of hard size threshold).
3. Raise runs-per-instance for stronger reference-best estimation.
4. Tune perturbation and acceptance parameters by dataset size band.

## Reproducibility

Comparison generator used:

- `compare_results.py`

Run command:

- `python compare_results.py`

Outputs:

- `output_comparison/*`
