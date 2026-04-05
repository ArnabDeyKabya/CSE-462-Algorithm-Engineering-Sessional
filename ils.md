# Iterated Local Search (ILS) for Team Orienteering Problem (TOP)

## 1. What this project solves

The Team Orienteering Problem (TOP) is a routing optimization problem where:

- You have one depot (start/end node), and many customer nodes.
- Each customer node has a reward (score).
- A fixed number of routes (team members/vehicles) must start and end at the depot.
- Each route has a maximum travel distance limit.
- A customer can be visited at most once globally across all routes.
- Goal: maximize total collected score while satisfying route distance limits.

This implementation solves TOP using **Iterated Local Search (ILS)** in:

- `top_ils.py`

This document explains everything from modeling to execution and output interpretation.

---

## 2. High-level algorithm idea

The solver follows this pattern:

1. Build an initial feasible solution using greedy randomized insertion.
2. Improve it with local search operators.
3. Perturb (partially destroy) the current solution.
4. Repair and improve again with local search.
5. Keep the better solutions and occasionally accept non-improving moves to escape local optima.
6. Periodically restart from a fresh constructive solution.
7. Return the best solution found.

This is classic ILS: **construct -> improve -> perturb -> improve -> accept/reject -> repeat**.

---

## 3. Mathematical objective and constraints

Let each route be a sequence starting and ending at depot 0.

Objective:

$$
\max \sum_{i \in V_{visited}} s_i
$$

Where:

- $s_i$ is score of node $i$
- $V_{visited}$ is set of visited non-depot nodes

Constraints:

- Each route starts at depot 0 and ends at depot 0.
- Route length $L_r \le L_{max}$ for every route $r$.
- Every non-depot node can appear in at most one route.

---

## 4. Code structure overview

Main file:

- `top_ils.py`

Main data classes:

- `TOPInstance`: problem input
- `TOPSolution`: routes + total score

Main solver API:

- `solve_top_ils(instance, iterations=300, seed=None, alpha=0.2, remove_fraction=0.25, restart_interval=80)`

Support layers:

- Geometry/utilities (distance matrix, route length, score)
- Construction heuristic
- Local search operators
- Perturbation operator
- Demo and pretty-print helper

---

## 5. Input model in detail

The algorithm expects a `TOPInstance` object with these fields:

### 5.1 `coordinates`

- Type: sequence of `(x, y)` tuples
- Index `0` must be the depot
- Indices `1..n-1` are candidate customer nodes

Example:

```python
coordinates = [
    (0, 0),  # depot
    (2, 2),
    (4, 1),
]
```

### 5.2 `scores`

- Type: sequence of numeric rewards
- Must have same length as `coordinates`
- `scores[0]` should generally be `0` for depot

Example:

```python
scores = [0, 8, 6]
```

### 5.3 `team_size`

- Number of routes to build
- Must be positive

### 5.4 `max_route_distance`

- Distance budget for each route
- Must be positive

### 5.5 Input validation

`TOPInstance.__post_init__` checks:

- equal lengths for coordinates and scores
- at least 2 nodes (depot + one customer)
- positive team size
- positive max route distance

If invalid, it raises `ValueError`.

---

## 6. Output model in detail

Solver returns a `TOPSolution`:

- `routes`: list of routes, each route is list of node IDs
- `total_score`: total unique score collected by all routes

Route format example:

```python
[
    [0, 1, 8, 5, 0],
    [0, 6, 3, 2, 0]
]
```

Properties:

- each route starts and ends with `0`
- non-depot nodes appear at most once globally
- each route should satisfy distance budget by construction/search checks

---

## 7. Step-by-step implementation walkthrough

### 7.1 Distance preprocessing

Functions:

- `_euclidean(a, b)`
- `_distance_matrix(coords)`

Behavior:

- Builds a full symmetric distance matrix once
- Makes route/neighbor evaluations faster in iterative search

### 7.2 Route and score helpers

Functions:

- `_route_length(route, dist)`
- `_visited_set(routes)`
- `_total_score(routes, scores)`

Behavior:

- Computes total distance of one route
- Extracts unique visited customers
- Computes total objective score (no duplicate counting)

### 7.3 Best insertion primitive

Function:

- `_best_insertion_for_node(node, routes, dist, max_route_distance)`

Behavior:

- Tries inserting node between every consecutive edge `(i, j)` of every route
- Computes insertion cost:

$$
\Delta = d(i,node) + d(node,j) - d(i,j)
$$

- Keeps best feasible insertion that does not violate route length cap

This primitive is reused by construction and local search insertion.

### 7.4 Initial solution (constructive phase)

Function:

- `_construct_initial_solution(instance, dist, rng, alpha)`

Behavior:

1. Initializes all routes as `[0, 0]`.
2. Maintains unvisited set of candidate nodes.
3. For each unvisited node, finds best feasible insertion.
4. Scores candidate with greedy value:

$$
\text{value} = \frac{score(node)}{1 + \Delta}
$$

5. Sorts candidates descending by value.
6. Uses a GRASP-style RCL: select randomly among top `ceil(alpha * candidates)`.
7. Inserts selected node and repeats until no feasible candidate remains.

Why randomized greedy?

- Pure greedy can be deterministic and stuck in similar local basins.
- RCL randomness increases diversity for better ILS exploration.

### 7.5 Local search phase

Function:

- `_local_search(solution, instance, dist)`

This loop applies three operators until no improvement-style move is found.

#### Operator A: 2-opt inside each route

Function:

- `_two_opt_route(route, dist, max_route_distance)`

Behavior:

- Tries edge exchanges by reversing a route segment.
- Uses best improving delta move (distance reduction).
- Accepts only if resulting route remains under max distance.

Purpose:

- Improve geometric shape and reduce route length.
- Freed route budget can later allow additional high-score insertions.

#### Operator B: Insert unvisited node

Function:

- `_try_insert_unvisited(routes, unvisited, instance, dist)`

Behavior:

- Finds best feasible insertion of one unvisited node.
- Ranking uses:

$$
\frac{score(node)}{1 + \Delta}
$$

- Applies best move if available.

Purpose:

- Directly improves objective by adding reward nodes.

#### Operator C: Swap visited with unvisited

Function:

- `_try_swap_with_unvisited(routes, unvisited, instance, dist)`

Behavior:

- For every currently visited node in a route position, try replacing with each unvisited node.
- Checks route feasibility after replacement.
- Chooses move with best positive score change:

$$
\Delta score = score(new) - score(old)
$$

- Executes best positive swap if any.

Purpose:

- Replaces low-value selected nodes with better ones.

Operator scheduling in code:

1. Run 2-opt on all routes
2. Try insert-unvisited (preferred)
3. If insertion not applied, try swap-with-unvisited
4. Repeat while any change occurred

### 7.6 Perturbation (kick move)

Function:

- `_perturb(solution, instance, dist, rng, remove_fraction)`

Behavior:

1. Collect all visited non-depot nodes.
2. Remove random subset of size:

$$
k = \max(1, \lceil remove\_fraction \cdot visited\_count \rceil)
$$

3. Repair route shape to maintain `[0, ..., 0]`.
4. Run local search to refill/improve.

Purpose:

- Escape local optimum by controlled destruction and repair.

### 7.7 ILS master loop

Function:

- `solve_top_ils(...)`

Flow:

1. Validate parameters (`alpha`, `remove_fraction`, `iterations`).
2. Build distance matrix once.
3. Construct + local search for initial current solution.
4. Keep `best = current`.
5. For each iteration:
   - perturb current
   - local search repair/improve
   - if candidate better than current: accept
   - else accept with small probability (`0.08`) as random walk
   - update global best if improved
   - every `restart_interval`, build fresh constructive solution and keep if better
6. Return `best`.

Acceptance logic rationale:

- Strictly better candidates are always accepted.
- Occasional non-improving acceptance helps avoid stagnation.
- Restarts provide larger diversification.

---

## 8. How to run

From workspace folder:

```powershell
& "f:/Academic/Algorithm Engineering Sessional/.venv/Scripts/python.exe" "f:/Academic/Algorithm Engineering Sessional/top_ils.py"
```

Expected demo output shape:

```text
Total score: <number>
Route 1: 0 -> ... -> 0 | score=<number>, length=<number>
Route 2: 0 -> ... -> 0 | score=<number>, length=<number>
...
```

---

## 9. How to use the solver with your own data

Minimal usage:

```python
from top_ils import TOPInstance, solve_top_ils

coords = [
    (0, 0),
    (2, 2),
    (4, 1),
    (6, 3),
]
scores = [0, 8, 6, 9]

instance = TOPInstance(
    coordinates=coords,
    scores=scores,
    team_size=2,
    max_route_distance=20.0,
)

best = solve_top_ils(
    instance,
    iterations=500,
    seed=42,
    alpha=0.25,
    remove_fraction=0.30,
    restart_interval=100,
)

print(best.total_score)
print(best.routes)
```

---

## 10. Parameter guide

### 10.1 `iterations`

- More iterations: usually better quality, more runtime
- Start with 200-1000 depending on instance size

### 10.2 `alpha`

- Range `(0, 1]`
- Smaller `alpha`: greedier construction
- Larger `alpha`: more randomness/diversification
- Typical: 0.15-0.35

### 10.3 `remove_fraction`

- Range `(0, 1]`
- Small values: gentle perturbations
- Large values: stronger diversification but less continuity
- Typical: 0.20-0.40

### 10.4 `restart_interval`

- Periodic reset frequency
- Smaller value: frequent diversification
- Larger value: deeper search around current basin

### 10.5 `seed`

- Set integer for reproducible runs
- Leave `None` for non-deterministic behavior

---

## 11. Feasibility guarantees in the code

Feasibility is protected at multiple points:

- All insertions check route length limit before applying.
- All swaps check resulting route length.
- 2-opt move is accepted only if route stays feasible.
- Perturbation repair keeps routes in depot-to-depot format.

These checks ensure returned routes remain valid with respect to distance constraints.

---

## 12. Time complexity (practical view)

Let:

- $n$ = number of nodes
- $m$ = team size

Dominant costs per iteration come from local search move evaluations:

- insertion checks: roughly $O(n \cdot m \cdot route\_length)$
- swap checks: can approach $O(n^2)$ in dense evaluation style
- 2-opt per route: $O(route\_length^2)$

Overall runtime depends heavily on:

- number of iterations
- how full routes are
- instance geometry and constraints

This implementation is suitable for small to medium TOP instances and as a strong educational baseline.

---

## 13. Strengths and limitations

Strengths:

- Clean and modular implementation
- Good balance of intensification (local search) and diversification (perturb + restart)
- Reproducible via random seed
- Easy to extend with additional neighborhoods

Limitations:

- No advanced memory structures (tabu list, elite pool)
- No adaptive parameter control
- No exact bounds or optimality guarantee (metaheuristic)
- For very large instances, may require stronger move pruning or parallelization

---

## 14. Suggested improvements (if you extend later)

- Add inter-route relocate and inter-route 2-opt* operators.
- Add elite solution pool and path relinking.
- Add adaptive perturbation size.
- Add multi-start parallel runs and keep best.
- Add instance file parser and batch benchmark runner.
- Add logging per iteration (current score, best score, acceptance stats).

---

## 15. Current demo instance summary

In the included demo, the solver uses:

- 9 total nodes including depot
- 2 routes (`team_size=2`)
- max route distance = 18.0
- 400 ILS iterations

A sample run produced:

- total score = 56.00
- route 1: `0 -> 1 -> 8 -> 5 -> 0`
- route 2: `0 -> 6 -> 3 -> 2 -> 0`

(Exact result can vary with parameters/seed.)

---

## 16. File list in this workspace

- `top_ils.py`: implementation
- `ils.md`: this explanation document

---

## 17. Quick recap

This code implements a complete ILS pipeline for TOP:

- randomized greedy construction
- local search improvement (2-opt, insertion, swap)
- perturb-and-repair cycle
- acceptance + occasional random walk
- periodic restart
- best-solution tracking

Use `solve_top_ils` as the main API and tune parameters based on instance size and runtime budget.
