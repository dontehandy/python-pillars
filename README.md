# Python Pillars

A living, evidence-based standard for writing and designing Python — organised into six pillars, each with
measurable pass/fail gates, and a rule that every exception is a recorded, expiring trade-off.

1. **Security** — always first
2. **Correctness**
3. **Performance** — measured with budgets and benchmarks, never guessed
4. **Maintainability**
5. **Architecture**
6. **Reliability**

Start with [`PRINCIPLES.md`](PRINCIPLES.md).

## What's here

| Path | What it is |
|---|---|
| `PRINCIPLES.md` | The six pillars: rules, gates with thresholds, sources, and the design-review checklist |
| `PRINCIPLES-CHANGELOG.md` | Every accepted change, with its source |
| `template/` | A project template that enforces the gates: `scripts/check.sh` prints a per-pillar scorecard |
| `template/tradeoffs.toml`, `template/docs/decisions/` | How exceptions work: a decision record with an options × pillars matrix, plus an expiring waiver |
| `digests/` | Weekly reviews of new releases, advisories, studies, blogs and podcasts — what was adopted, rejected, and why |
| `feed/SOURCES.md` | The sources reviewed each week and how much each is trusted |
| `tools/` | `fetch-sources.sh` (downloads the reference texts the principles cite) and `new-project.sh` |

## Use it

```bash
git clone https://github.com/dontehandy/python-pillars
cd python-pillars
tools/fetch-sources.sh                 # optional: download the cited PEPs, guides and books into sources/
tools/new-project.sh my-app ~/code     # new project from the template, with .venv and dev tools
cd ~/code/my-app && scripts/check.sh   # pillar scorecard
```

Requires Python 3.13+, git, and zsh (default on macOS; `apt install zsh` on Linux). Optional: `gitleaks` for the
secrets gate.

Every gate must **PASS**, or be **WAIVED** by a trade-off recorded in `tradeoffs.toml` that links a decision
record and expires (security trade-offs: 30 days max). Expired waivers fail again.

## How it's maintained

New information is gathered and fact-checked weekly **with AI assistance** (Claude agents). Every claim must
trace to a primary source — an official release, PEP, advisory, benchmark, or the actual study — and claims the
evidence can't support are rejected, with the reason recorded in the weekly digest. **Every change is reviewed
and merged by me.**

**This public edition is published on a one-month delay.** A weekly-updated edition, which also scans codebases
against the pillars and proposes fixes with their trade-offs, is maintained privately.

## License

- Written content (principles, digests, docs): **CC BY-NC 4.0** — use and adapt it with credit, not commercially.
- Code (`template/`, `tools/`): **PolyForm Noncommercial 1.0.0**.

See [`LICENSE.md`](LICENSE.md). Commercial use requires permission — open an issue to ask.

## Disclaimer

Provided **as is**, without warranty of any kind. This is guidance, not a guarantee: you are responsible for how
you apply it, and for verifying that it fits your project. The authors are not liable for any outcome of its use.

## Credits

The principles are distilled from, and cite: the Python PEPs and documentation; the Google Python Style Guide;
*Architecture Patterns with Python* (Percival & Gregory); The Hitchhiker's Guide to Python; The Twelve-Factor App;
the OWASP Cheat Sheet Series; and the pytest and PyPA guides. Those works keep their own licenses and are not
redistributed here — `tools/fetch-sources.sh` downloads them from their publishers.
