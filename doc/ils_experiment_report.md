# Iterated Local Search for Team Orienteering Problem

## 1. Project Scope

This project implements and evaluates an Iterated Local Search (ILS) algorithm for the Team Orienteering Problem (TOP) on three standard benchmark families:

- Chao benchmark
- Dang benchmark
- Vansteenwegen OP/TOP benchmark range

The workflow covers:

- Dataset preparation and organization
- Parsing benchmark instance files
- Solving each instance with ILS
- Measuring computational and solution-quality metrics
- Aggregating metrics at run, instance, and dataset levels
- Producing analysis-ready CSV outputs and a runtime-vs-instance-size plot

## 2. Problem Definition

In TOP, we are given:

- A set of nodes with coordinates and rewards (scores)
- A team size m (number of routes/vehicles)
- A route distance limit tmax for each route

Objective:

- Maximize total collected score

Constraints:

- Each route starts and ends at a depot
- Route distance must not exceed tmax
- A customer node can be visited at most once globally

## 3. Core Implementation

Main implementation file:

- [top_ils.py](../top_ils.py)

### 3.1 Data Model

The solver uses:

- TOPInstance: coordinates, scores, team size, max route distance, depot indices
- TOPSolution: set of routes and total score
- ILSStats: runtime and convergence metrics

### 3.2 Constructive Phase

The initial solution is built using a greedy randomized insertion strategy:

- Start from empty depot-to-depot routes
- For each unvisited node, find best feasible insertion position
- Rank candidate insertions by score divided by insertion distance penalty
- Choose randomly from a restricted candidate list controlled by alpha

This balances exploitation and diversification at initialization.

### 3.3 Local Search Phase

Local search repeatedly applies:

- 2-opt within each route to reduce route length
- Insertion of unvisited nodes if feasible
- Swap of visited and unvisited nodes when score increases and feasibility holds

This continues until no improving move is found.

### 3.4 Perturbation in ILS

At each ILS iteration:

- Remove a random fraction of currently visited nodes
- Repair route shape to keep valid depot boundaries
- Re-optimize with local search

This allows the search to escape local optima.

### 3.5 Acceptance and Restart

- Better candidates are accepted
- Some non-improving candidates are accepted with low probability for diversification
- Periodic restarts reconstruct solutions to avoid long stagnation

## 4. Dataset Preparation

Preparation script:

- [prepare_datasets.ps1](../prepare_datasets.ps1)

Run orchestration script:

- [run_experiment.ps1](../run_experiment.ps1)

Dataset folder:

- [datasets](../datasets)

Prepared dataset subfolders and counts:

- Chao: 240 instances in [datasets/chao](../datasets/chao)
- Dang: 82 instances in [datasets/dang](../datasets/dang)
- Vansteenwegen range: 67 instances in [datasets/vansteenwegen](../datasets/vansteenwegen)

Total instances evaluated:

- 389

Each instance was run 2 times (run00, run01), so total runs:

- 778

## 5. Experiment Configuration

Configuration used in the current run is stored in:

- [output/metrics_overview.json](../output/metrics_overview.json)

Key settings:

- iterations: 20
- runs per instance: 2
- seed base: 7
- alpha: 0.25
- remove fraction: 0.30
- restart interval: 20

## 6. Metrics Implemented

### 6.1 Per-run metrics

Stored in:

- [output/summary.csv](../output/summary.csv)

Includes:

- total score
- CPU time in seconds
- iterations
- iterations to convergence
- last improvement iteration
- stagnation iterations
- accepted worse moves
- restarts performed

### 6.2 Gap metric

Requested metric:

- Gap to optimum

Current implementation:

- Gap to reference best score found across repeated runs of the same instance

Field names:

- reference_best_score
- gap_to_reference_best_percent

Important note:

- This is not exact gap to proven global optimum for all instances.
- Rationale is documented in [output/metrics_overview.json](../output/metrics_overview.json).

### 6.3 Solution quality distribution

Stored in:

- [output/quality_distribution.csv](../output/quality_distribution.csv)

Also summarized per dataset with distribution statistics:

- score mean, std, p10, p50, p90 in [output/dataset_metrics.csv](../output/dataset_metrics.csv)

### 6.4 Success rate

Per run:

- success_reference_hit = 1 if run score equals reference_best_score of that instance

Aggregated:

- success_rate_percent in [output/instance_metrics.csv](../output/instance_metrics.csv)
- success_rate_percent in [output/dataset_metrics.csv](../output/dataset_metrics.csv)

### 6.5 Runtime vs instance size analysis

Data:

- [output/runtime_vs_instance_size.csv](../output/runtime_vs_instance_size.csv)

Plot:

- [output/runtime_vs_instance_size.png](../output/runtime_vs_instance_size.png)

## 7. Output Artifacts

Main outputs:

- [output/summary.csv](../output/summary.csv): one row per run
- [output/instance_metrics.csv](../output/instance_metrics.csv): aggregated per instance
- [output/dataset_metrics.csv](../output/dataset_metrics.csv): aggregated per dataset
- [output/quality_distribution.csv](../output/quality_distribution.csv): run-level quality distribution
- [output/runtime_vs_instance_size.csv](../output/runtime_vs_instance_size.csv): analysis table
- [output/runtime_vs_instance_size.png](../output/runtime_vs_instance_size.png): analysis plot
- [output/metrics_overview.json](../output/metrics_overview.json): run configuration and metric notes
- [output/instances](../output/instances): per-run JSON solutions for each instance

## 8. Dataset-level Results Summary

Source:

- [output/dataset_metrics.csv](../output/dataset_metrics.csv)

### Chao

- Instances: 240
- Runs: 480
- Mean CPU time: 0.1505 s
- Median CPU time: 0.1171 s
- P90 CPU time: 0.3542 s
- Mean iterations to convergence: 8.8042
- Mean gap to reference best: 1.1192%
- Median gap: 0.0%
- Success rate: 66.04%

### Dang

- Instances: 82
- Runs: 164
- Mean CPU time: 3.6324 s
- Median CPU time: 2.4669 s
- P90 CPU time: 11.3535 s
- Mean iterations to convergence: 14.8598
- Mean gap to reference best: 1.9077%
- Median gap: 0.0%
- Success rate: 53.66%

### Vansteenwegen range

- Instances: 67
- Runs: 134
- Mean CPU time: 2.4111 s
- Median CPU time: 2.0983 s
- P90 CPU time: 4.2764 s
- Mean iterations to convergence: 14.7985
- Mean gap to reference best: 1.9435%
- Median gap: 0.0%
- Success rate: 54.48%

## 9. Analysis and Interpretation

### 9.1 Runtime behavior

- Runtime strongly scales with instance size and complexity.
- Chao set is substantially faster than Dang and Vansteenwegen ranges under the same iteration budget.
- Runtime spread (P90) is much larger for Dang, indicating higher heterogeneity in instance difficulty.

### 9.2 Convergence behavior

- Chao converges earlier on average than Dang and Vansteenwegen.
- Dang and Vansteenwegen require more iterations before last improvement, suggesting harder local-search landscapes.

### 9.3 Solution stability

- Median gap equals 0.0% in all three datasets, meaning at least half of runs hit the reference best for their instance.
- Success rate is highest on Chao, lower on Dang/Vansteenwegen, consistent with observed complexity.

### 9.4 Quality distribution

- Score spread is wide in all datasets due to mixed instance sizes and budgets.
- Distribution metrics (p10/p50/p90) are necessary and more informative than a single average.

## 10. Important Notes and Limitations

1. Gap definition

- Current gap is to the best score found among repeated ILS runs, not always to proven optimum.
- This is practical for metaheuristic benchmarking when exact optima are unavailable.

2. Success rate interpretation

- success_reference_hit measures hit to reference best from repeated runs.
- It is not equivalent to exact-method optimality certification.

3. LP solves and label counts

- Metrics such as number of LP solves and number of labels generated are exact-method internals (B&P, DP pricing).
- For ILS, these are not applicable and are marked N/A.

4. Iteration budget

- Current experiments used 20 ILS iterations for full-scale completion speed.
- Higher iterations generally improve quality but increase CPU time.

## 11. Reproducibility

To rerun the full pipeline:

- Execute [run_experiment.ps1](../run_experiment.ps1)

This performs:

- dataset preparation
- benchmark experiments
- metrics aggregation
- runtime-vs-size plotting

## 12. Suggested Next Extensions

1. True gap-to-optimum mode

- Add a file of known best/optimal scores per instance and compute exact benchmark gap.

2. More robust statistics

- Increase runs per instance (for example, 10 or 30) for more stable distribution estimates.

3. Multi-configuration tuning

- Compare multiple parameter sets and include statistical significance tests.

4. Visual analytics

- Add boxplots and violin plots per dataset for score and runtime distributions.

5. Convergence traces

- Export per-iteration score curves for selected instances.

## 13. File Map

- Algorithm and experiment engine: [top_ils.py](../top_ils.py)
- Dataset preparation: [prepare_datasets.ps1](../prepare_datasets.ps1)
- End-to-end runner: [run_experiment.ps1](../run_experiment.ps1)
- Metrics outputs: [output](../output)
- This report: [doc/ils_experiment_report.md](ils_experiment_report.md)
