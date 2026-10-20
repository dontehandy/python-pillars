#!/bin/zsh
# Pillar scorecard: runs every gate from PRINCIPLES.md and prints PASS / WAIVED / FAIL per gate and pillar.
# A failing gate counts as WAIVED only if tradeoffs.toml has an unexpired waiver for its id that links a
# decision record (docs/decisions/). Security waivers may last at most 30 days.
# Usage (from anywhere in the project):  scripts/check.sh      Exit code is non-zero if any gate FAILs.

cd "${0:A:h}/.." || exit 1
BIN=.venv/bin
[[ -x $BIN/python ]] || { print "No .venv found. Create it: python3 -m venv .venv && .venv/bin/pip install -e '.[dev]'"; exit 1 }
PKG=$($BIN/python -c 'import tomllib; print(tomllib.load(open("pyproject.toml","rb"))["tool"]["importlinter"]["root_package"])')
budget() { $BIN/python -c "import tomllib; print(tomllib.load(open('pyproject.toml','rb'))['tool']['budgets']['$1'])" }

# Prints the waiver summary and returns 0 if gate $1 has a valid waiver; otherwise prints why not and returns 1.
waiver() {
  $BIN/python - "$1" <<'EOF'
import sys, tomllib, datetime, pathlib
gate = sys.argv[1]
p = pathlib.Path("tradeoffs.toml")
waivers = tomllib.loads(p.read_text()).get("waiver", []) if p.exists() else []
today = datetime.date.today()
for w in waivers:
    if w.get("gate") != gate:
        continue
    missing = [k for k in ("reason", "decision", "decided", "expires") if not w.get(k)]
    if missing:
        print(f"waiver for {gate} is missing: {', '.join(missing)}"); sys.exit(1)
    decided, expires = w["decided"], w["expires"]
    if not pathlib.Path(w["decision"]).exists():
        print(f"waiver decision record not found: {w['decision']}"); sys.exit(1)
    if gate.startswith("sec.") and (expires - decided).days > 30:
        print("security waivers may last at most 30 days"); sys.exit(1)
    if expires < today:
        print(f"waiver EXPIRED on {expires} — fix the gate or renew the decision"); sys.exit(1)
    print(f"{w['reason']} (until {expires}; {w['decision']})"); sys.exit(0)
sys.exit(1)
EOF
}

typeset -A result
fails=0
gate() {
  # $1 pillar, $2 gate id, $3 description, rest = command
  local pillar=$1 id=$2 name=$3; shift 3
  local out rc w wrc
  out=$("$@" 2>&1); rc=$?
  if (( rc != 0 && rc != 99 )); then w=$(waiver $id); wrc=$?; fi
  if (( rc == 0 )); then
    print -P "  %F{green}PASS%f    [$id] $name"
  elif (( rc == 99 )); then
    print -P "  %F{cyan}SKIP%f    [$id] $name — ${out:0:160}"
  elif (( wrc == 0 )); then
    print -P "  %F{yellow}WAIVED%f  [$id] $name — $w"
    [[ ${result[$pillar]} == FAIL ]] || result[$pillar]=TRADEOFF
  else
    print -P "  %F{red}FAIL%f    [$id] $name"; [[ -n $w ]] && print "          $w"
    print -r -- "$out" | tail -15 | sed 's/^/          /'
    result[$pillar]=FAIL; (( fails++ ))
  fi
}
header() { print -P "\n%B$1%b"; result[$1]=PASS }

lock_current() {
  [[ -f requirements.lock ]] || { print "requirements.lock missing (run: .venv/bin/pip freeze --exclude-editable > requirements.lock)"; return 1 }
  diff <($BIN/pip freeze --exclude-editable) requirements.lock
}
secrets_scan() {
  command -v gitleaks >/dev/null || { print "gitleaks not installed (brew install gitleaks)"; return 1 }
  gitleaks dir . --no-banner --redact
}
startup_budget() {
  local limit=$(budget startup_ms)
  local ms=$($BIN/python -c "
import subprocess, sys, time
t = time.perf_counter(); subprocess.run([sys.executable, '-c', 'import $PKG'], check=True)
print(int((time.perf_counter() - t) * 1000))")
  print "startup ${ms} ms (budget ${limit} ms)"
  (( ms <= limit ))
}
benchmarks() {
  local pct=$(budget benchmark_regression_pct)
  local saved=(.benchmarks/*/*.json(N))
  if (( ${#saved} )); then
    $BIN/pytest tests/benchmarks --benchmark-only --benchmark-compare --benchmark-compare-fail=mean:${pct}% -p no:cacheprovider
  else
    $BIN/pytest tests/benchmarks --benchmark-only --benchmark-autosave -p no:cacheprovider >/dev/null 2>&1 \
      && { print "no baseline yet — saved one; future runs compare against it"; return 99 }
  fi
}

header "1. Security"
gate "1. Security" sec.deps    "No known-vulnerable dependencies (pip-audit)" $BIN/pip-audit --skip-editable --progress-spinner off
gate "1. Security" sec.code    "No insecure code (ruff S)" $BIN/ruff check --select S src
gate "1. Security" sec.secrets "No committed secrets (gitleaks)" secrets_scan
gate "1. Security" sec.lock    "Lock file present and current" lock_current

header "2. Correctness"
gate "2. Correctness" cor.tests "Tests pass, coverage >= threshold" $BIN/pytest --cov --cov-report=term -p no:cacheprovider --benchmark-skip
gate "2. Correctness" cor.types "Strict type check (mypy)" $BIN/mypy

header "3. Performance"
gate "3. Performance" perf.startup "Startup within budget" startup_budget
gate "3. Performance" perf.bench   "No benchmark regression vs baseline" benchmarks

header "4. Maintainability"
gate "4. Maintainability" mnt.format "Formatted (ruff format)" $BIN/ruff format --check .
gate "4. Maintainability" mnt.lint   "Lint, complexity, docstrings (ruff)" $BIN/ruff check .

header "5. Architecture"
gate "5. Architecture" arch.layers "Layer contracts (import-linter)" $BIN/lint-imports

header "6. Reliability"
gate "6. Reliability" rel.logging "No print / blind except in src (ruff T20, BLE, E722)" $BIN/ruff check --select T20,BLE,E722 src

print -P "\n%BScorecard%b"
for p in "1. Security" "2. Correctness" "3. Performance" "4. Maintainability" "5. Architecture" "6. Reliability"; do
  case ${result[$p]} in
    PASS)     print -P "  %F{green}PASS%f              $p" ;;
    TRADEOFF) print -P "  %F{yellow}PASS w/ tradeoff%f  $p" ;;
    *)        print -P "  %F{red}FAIL%f              $p" ;;
  esac
done
(( fails == 0 ))
