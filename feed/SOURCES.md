# Feed sources

What the scheduled agents read. Add or remove lines freely; agents read this file every run.
Tier sets how much a source can be trusted on its own (see PROCESS.md).

## Tier 1 — primary / official (can justify a change alone)
- Python Insider (releases, security releases): https://blog.python.org
- PEPs (new, accepted, final): https://peps.python.org and https://discuss.python.org/c/peps/19
- Python docs "What's New": https://docs.python.org/3/whatsnew/
- PSF blog: https://pyfound.blogspot.com
- PyPI blog: https://blog.pypi.org
- PyPA packaging guide: https://packaging.python.org
- Tool changelogs: ruff / uv (https://astral.sh/blog), pytest (https://docs.pytest.org/en/stable/changelog.html), mypy (https://mypy-lang.blogspot.com)
- Peer-reviewed or preprint studies (ACM, IEEE, arXiv cs.SE) — only with the paper itself linked

## Tier 1 — security
- PyPA Advisory Database: https://github.com/pypa/advisory-database
- GitHub Advisory Database (pip ecosystem): https://github.com/advisories?query=ecosystem%3Apip
- OSV: https://osv.dev/list?ecosystem=PyPI
- Python security announcements: https://mail.python.org/archives/list/security-announce@python.org/
- Seth Larson (PSF Security Developer-in-Residence): https://sethmlarson.dev
- OWASP Cheat Sheets / Top 10: https://cheatsheetseries.owasp.org , https://owasp.org/Top10/
- CISA Known Exploited Vulnerabilities: https://www.cisa.gov/known-exploited-vulnerabilities-catalog

## Tier 2 — expert practitioners (need corroboration)
- Real Python (articles + podcast): https://realpython.com , https://realpython.com/podcasts/rpp/
- Talk Python To Me (podcast): https://talkpython.fm
- Python Bytes (podcast): https://pythonbytes.fm
- PyCoder's Weekly: https://pycoders.com
- Hynek Schlawack: https://hynek.me/articles/
- Brett Cannon: https://snarky.ca
- Simon Willison (Python + AI tooling): https://simonwillison.net
- Cosmic Python blog: https://www.cosmicpython.com/blog/
- Martin Fowler (architecture): https://martinfowler.com

## Tier 3 — signal only (never justifies a change by itself)
- Hacker News, Reddit r/Python, social media, vendor marketing, newsletters summarising other sources.
