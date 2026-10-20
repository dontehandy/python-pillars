# Python Principles

The rulebook for Python code and system design, organised into **six pillars**. Every pillar has rules (what to
do), **gates** (measurable pass/fail checks run by `template/scripts/check.sh`), and sources (in `sources/`).
Pillars are reviewed weekly against new, verified information (see `feed/PROCESS.md`).

## Precedence

1. **Security** — always on, always first. Never traded away for speed, convenience, or style.
2. **Correctness** — wrong-but-fast or wrong-but-pretty is still wrong.
3. **Performance**, **Maintainability**, **Architecture**, **Reliability** — balanced per project, guided by
   the project's declared budgets.

When a project's own conventions differ, follow the project and note the difference. When sources disagree:
official Python docs/PEPs > this file > Google guide > everything else.

## Pass, or record the trade-off

Every gate must **PASS**. If a decision means a gate can't pass, that is allowed only as a recorded trade-off:
1. Write a **decision record** in `docs/decisions/NNNN-title.md` (from `template/docs/decisions/0000-template.md`)
   with the **options × pillars matrix**: each option scored ✓ meets / ~ trade-off / ✗ fails per pillar,
   with evidence (measurements, sources). An option that is ✗ on Security is not eligible.
2. Add a `[[waiver]]` in `tradeoffs.toml` naming the gate id, reason, decision record, decided date and
   **expiry**. The scorecard then shows WAIVED instead of FAIL; once expired it fails again.
3. **Security waivers last at most 30 days.** Other waivers should be reviewed within 3 months.

Any significant design choice (new dependency, storage, framework, architecture layer, concurrency model) gets
a decision record with the matrix, even when every gate passes.

## Tie-breakers (Zen of Python, `peps/pep-0020.rst`)

Explicit beats implicit. Simple beats complex; complex beats complicated. Flat beats nested. Readability
counts. Errors should never pass silently. One obvious way to do it.

## Gate summary

| # | Pillar | Gate | Threshold | Tool |
|---|---|---|---|---|
| 1 | Security | Known-vulnerable dependencies | **0** | `pip-audit` |
| 1 | Security | Insecure-code findings (bandit rules) | **0** (justified per-line exceptions only) | `ruff --select S` |
| 1 | Security | Secrets committed | **0** | `gitleaks` |
| 1 | Security | Dependencies pinned (lock file) | present, up to date | `requirements.lock` |
| 2 | Correctness | Tests passing | **100%** | `pytest` |
| 2 | Correctness | Line coverage of `src/` | **≥ 85%** (domain code ≥ 95%) | `pytest-cov` |
| 2 | Correctness | Type errors (strict) | **0** | `mypy --strict` |
| 3 | Performance | Benchmark regression vs saved baseline | **≤ 10% slower** (mean) | `pytest-benchmark` |
| 3 | Performance | Declared budgets (latency / memory / startup) | all within budget | benchmark + `tracemalloc` tests |
| 4 | Maintainability | Format and lint | **0** issues | `ruff format --check`, `ruff check` |
| 4 | Maintainability | Cyclomatic complexity per function | **≤ 10** | `ruff` C901 |
| 4 | Maintainability | Public API docstrings | **100%** | `ruff` D (Google convention) |
| 5 | Architecture | Layer rules (domain imports no adapters) | **0** broken contracts | `import-linter` |
| 6 | Reliability | `print` in library code, bare/blind `except` | **0** | `ruff` T20, E722, BLE |

Scorecard: `scripts/check.sh` runs every gate and prints PASS/FAIL per pillar. A project is "green" when all pass.

---

## Pillar 1 — Security (always first)

**Goal:** no known vulnerabilities, no secrets in code, untrusted input never trusted.

Rules:
- **Dependencies:** pin exact versions in a lock file; audit with `pip-audit` on every change and weekly; update
  within the same major promptly when a fix exists (`owasp/Vulnerable_Dependency_Management_Cheat_Sheet.md`).
  Install only well-known packages; check the name for typosquats before adding
  (`owasp/Software_Supply_Chain_Security_Cheat_Sheet.md`).
- **Secrets:** never in code, git, logs or error messages. Load from environment / a secrets manager; `.env` only
  for local dev and git-ignored (`owasp/Secrets_Management_Cheat_Sheet.md`; `twelve-factor/config.md`).
  Generate tokens with `secrets`, never `random` (`python-docs/secrets.rst`).
- **Untrusted input:** validate at the boundary with an allow-list (types, ranges, formats) — Pydantic or
  dataclass validation (`owasp/Input_Validation_Cheat_Sheet.md`).
- **Injection:** parameterised SQL only — never build queries with f-strings/concatenation
  (`owasp/SQL_Injection_Prevention_Cheat_Sheet.md`). `subprocess` with a list of args, never `shell=True` with
  input (`owasp/Injection_Prevention_Cheat_Sheet.md`).
- **Dangerous built-ins** (`python-docs/security_warnings.rst`): never `pickle`, `marshal`, `shelve`, `eval`,
  `exec` or `yaml.load` on untrusted data (`python-docs/pickle.rst`, `owasp/Deserialization_Cheat_Sheet.md`).
  Use JSON and `yaml.safe_load`.
- **Passwords:** hash with Argon2id (or bcrypt/scrypt) via a vetted library; never plain hashes
  (`owasp/Password_Storage_Cheat_Sheet.md`).
- **Logging:** log security events, never log secrets/tokens/personal data (`owasp/Logging_Cheat_Sheet.md`).
- **Runtime:** stay on a supported Python version (currently 3.13; security fixes until 2029-10).
- **Least privilege:** services and DB users get only the permissions they need.

## Pillar 2 — Correctness

**Goal:** the code does what it claims, proven by tests and types.

Rules:
- **pytest** with plain `assert`, fixtures, `parametrize` (`tooling/pytest-good-practices.rst`;
  `hitchhikers/tests.rst`). Test behaviour through public interfaces.
- Test shape: many fast unit tests on domain/service code using fakes; a few integration tests against real
  adapters; very few end-to-end (`cosmic-python/chapter_05_high_gear_low_gear.asciidoc`).
- Fakes over mocks: an in-memory `FakeRepository` implementing the `Protocol` beats `mock.patch` chains.
- **Type-annotate everything public**, check strictly (`peps/pep-0484.rst`; `google/pyguide.md` 2.21, 3.19).
  Modern syntax: `list[str]`, `X | None`. Interfaces as `typing.Protocol` (`peps/pep-0544.rst`).
- Errors: raise specific exceptions (built-ins or a small hierarchy under one `AppError`); catch the narrowest
  type; never swallow (`google/pyguide.md` 2.4).
- Never use mutable default arguments (`google/pyguide.md` 2.12). No mutable global state (2.5).

## Pillar 3 — Performance (measured, not guessed)

**Goal:** meet declared budgets and never get slower by accident.

Rules:
- **Declare budgets** in each project's `pyproject.toml` under `[tool.budgets]` — e.g. key operation p95
  latency (ms), peak memory (MB) for a known workload, CLI startup time (ms). No budget, no performance claims.
- **Measure before optimising.** Profile to find the real hotspot: `cProfile`/`pstats` for CPU
  (`python-docs/profile.rst`), `python -X importtime` for startup, `tracemalloc` for memory
  (`python-docs/tracemalloc.rst`), `timeit` for micro-comparisons (`python-docs/timeit.rst`),
  `perf` integration for system-level (`python-docs/perf_profiling.rst`).
- **Benchmark critical paths** with `pytest-benchmark`; save a baseline; the gate fails if the mean regresses
  more than 10%. Update the baseline only deliberately, in its own commit, with the reason.
- **Order of fixes:** better algorithm/data structure (O(n²) → O(n log n), `set`/`dict` lookups) → avoid repeated
  work (caching with `functools.cache`, batching I/O and DB queries, no N+1 queries) → built-ins and
  vectorised libraries (numpy/pandas) → concurrency (`asyncio` for I/O-bound, `multiprocessing` for CPU-bound) →
  only then native extensions.
- Generators/streaming for large data; don't load what you don't need (`google/pyguide.md` 2.9).
- Keep Python current within the supported line — each release brings measured speedups.

## Pillar 4 — Maintainability (readable by people and AI)

**Goal:** a newcomer — human or AI assistant — can understand and safely change the code.

Rules:
- PEP 8 (`peps/pep-0008.rst`), enforced by **ruff** — never hand-format.
- Naming (`pep-0008.rst` "Naming Conventions"; `google/pyguide.md` 3.16): `snake_case`, `PascalCase` classes,
  `UPPER_CASE` constants, `_private`. Names say what a thing is.
- Imports: absolute, grouped stdlib / third-party / local (`google/pyguide.md` 2.2, 3.13).
- **Docstrings** on every public module/class/function, Google style (`peps/pep-0257.rst`;
  `google/pyguide.md` 3.8). **Comments explain *why*** — intent, constraints, trade-offs — not what the code
  already says. Good docstrings and comments are what let AI assistants modify code correctly; they have no
  runtime cost (CPython discards comments).
- Small functions doing one thing; complexity ≤ 10 (`google/pyguide.md` 3.18).
- Idioms: iterate directly (`enumerate`, `zip`); comprehensions for simple transforms only; truthiness checks
  (`if items:`; `is None` for None); `with` for resources; `pathlib`; f-strings; `dataclasses`
  (`google/pyguide.md` 2.7, 2.8, 2.14, 3.11). Avoid metaclasses and other power features (2.19).
- `if __name__ == "__main__":` + `main()` for scripts (`google/pyguide.md` 3.17).

## Pillar 5 — Architecture (system design)

**Goal:** structure that matches the problem — no more, no less.
Primary source: *Architecture Patterns with Python* (`sources/cosmic-python/`).

Decision ladder — add a layer only when its trigger appears:

| Situation | Use | Source |
|---|---|---|
| One-off script / notebook | Plain functions, `main()` | — |
| Logic worth testing apart from I/O | Functional core, imperative shell | `chapter_03_abstractions` |
| Real business rules | Domain model: plain classes, no framework/DB imports | `chapter_01_domain_model` |
| A database is involved | Repository behind a `Protocol` | `chapter_02_repository` |
| Multiple entry points (API, CLI, jobs) | Service layer: one function per use case | `chapter_04_service_layer` |
| Atomic commit/rollback | Unit of Work | `chapter_06_uow` |
| Wiring getting tangled | `bootstrap()` composition root (no DI framework) | `chapter_13_dependency_injection` |
| Decoupled side effects | Domain events + message bus | `chapter_08`, `chapter_09` |

Always: dependencies point inward (domain ← services ← adapters), enforced by `import-linter` contracts.
If testing a rule needs a database, the boundary is in the wrong place. Abstractions must earn their place.

Layout (`tooling/writing-pyproject-toml.rst`; `peps/pep-0621.rst`; `hitchhikers/structure.rst`):
src layout + `pyproject.toml` + `tests/` + per-project `.venv`. Single-file scripts declare dependencies with
PEP 723 inline metadata (`peps/pep-0723.rst`). Start new projects from `template/`.

## Pillar 6 — Reliability and operations

**Goal:** runs the same everywhere, fails loudly and recoverably, and can be diagnosed.

Rules (Twelve-Factor, `sources/twelve-factor/`):
- Config from environment variables, read once at startup into a typed settings object (`config.md`).
- Backing services (DB, cache, queues) are attached resources chosen by config (`backing-services.md`).
- `logging`, not `print`: libraries use `logging.getLogger(__name__)`; only the entry point configures handlers;
  logs go to stdout/stderr as an event stream (`logs.md`; `hitchhikers/logging.rst`).
- Stateless processes, fast startup, graceful shutdown on SIGTERM (`processes.md`, `disposability.md`).
- Dev/prod parity: same backing services everywhere — Postgres locally, not SQLite (`dev-prod-parity.md`).
- External calls get timeouts and bounded retries with backoff; never retry non-idempotent operations blindly.

---

## Design review checklist

1. **Security:** any new input, dependency, secret, query, subprocess or deserialisation? Gate clean?
2. **Correctness:** tests for the new behaviour? Types strict-clean?
3. **Performance:** does it touch a budgeted path? Benchmark within 10% of baseline?
4. **Maintainability:** would a newcomer understand it? Docstrings and *why*-comments present?
5. **Architecture:** is every layer justified by the ladder? Does the domain import anything outward?
6. **Reliability:** config from env, logging not print, timeouts on external calls?
7. `scripts/check.sh` all green.
