#!/usr/bin/env bash
# Download the reference texts that PRINCIPLES.md cites into sources/, from their original publishers.
# They keep their own licenses and are not redistributed in this repository.
# Usage: tools/fetch-sources.sh
set -euo pipefail
cd "$(dirname "$0")/.."
S=sources
mkdir -p $S/{peps,google,hitchhikers,cosmic-python,twelve-factor,tooling,python-docs,owasp}

fetch() { curl -fsSL --retry 2 -o "$1" "$2" && echo "ok   $1" || echo "FAIL $1 ($2)"; }

for p in 0008 0020 0257 0484 0544 0621 0723; do
  fetch "$S/peps/pep-$p.rst" "https://raw.githubusercontent.com/python/peps/main/peps/pep-$p.rst"
done
fetch $S/google/pyguide.md https://raw.githubusercontent.com/google/styleguide/gh-pages/pyguide.md
for f in structure style tests logging; do
  fetch "$S/hitchhikers/$f.rst" "https://raw.githubusercontent.com/realpython/python-guide/master/docs/writing/$f.rst"
done
for f in introduction preface chapter_01_domain_model chapter_02_repository chapter_03_abstractions \
         chapter_04_service_layer chapter_05_high_gear_low_gear chapter_06_uow chapter_07_aggregate \
         chapter_08_events_and_message_bus chapter_09_all_messagebus chapter_10_commands \
         chapter_11_external_events chapter_12_cqrs chapter_13_dependency_injection \
         epilogue_1_how_to_get_there_from_here appendix_project_structure; do
  fetch "$S/cosmic-python/$f.asciidoc" "https://raw.githubusercontent.com/cosmicpython/book/master/$f.asciidoc"
done
for f in intro codebase dependencies config backing-services build-release-run processes port-binding \
         concurrency disposability dev-prod-parity logs admin-processes; do
  fetch "$S/twelve-factor/$f.md" "https://raw.githubusercontent.com/heroku/12factor/master/content/en/$f.md"
done
fetch $S/tooling/pytest-good-practices.rst https://raw.githubusercontent.com/pytest-dev/pytest/main/doc/en/explanation/goodpractices.rst
fetch $S/tooling/writing-pyproject-toml.rst https://raw.githubusercontent.com/pypa/packaging.python.org/main/source/guides/writing-pyproject-toml.rst
B=https://raw.githubusercontent.com/python/cpython/3.13/Doc
for f in library/security_warnings library/profile howto/perf_profiling library/timeit library/tracemalloc \
         library/secrets library/pickle; do
  fetch "$S/python-docs/$(basename $f).rst" "$B/$f.rst"
done
for c in Injection_Prevention SQL_Injection_Prevention Secrets_Management Deserialization Input_Validation \
         Logging Password_Storage Vulnerable_Dependency_Management Software_Supply_Chain_Security; do
  fetch "$S/owasp/${c}_Cheat_Sheet.md" "https://raw.githubusercontent.com/OWASP/CheatSheetSeries/master/cheatsheets/${c}_Cheat_Sheet.md"
done
