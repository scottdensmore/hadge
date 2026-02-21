#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

failures=0
warnings=0

pass() {
  echo "PASS: $1"
}

warn() {
  echo "WARN: $1"
  warnings=$((warnings + 1))
}

fail() {
  echo "FAIL: $1"
  failures=$((failures + 1))
}

check_cmd() {
  local cmd="$1"
  local required="$2"

  if command -v "${cmd}" >/dev/null 2>&1; then
    pass "command available: ${cmd}"
  else
    if [ "${required}" = "required" ]; then
      fail "missing required command: ${cmd}"
    else
      warn "missing optional command: ${cmd}"
    fi
  fi
}

echo "Running Hadge environment checks from ${ROOT_DIR}"

check_cmd git required
check_cmd make required
check_cmd xcodebuild required
check_cmd xcrun required
check_cmd brew optional
check_cmd swiftlint optional
check_cmd sourcery optional
check_cmd gh optional

if command -v xcodebuild >/dev/null 2>&1; then
  xcode_version="$(xcodebuild -version 2>/dev/null | head -n 1 || true)"
  if [ -n "${xcode_version}" ]; then
    pass "${xcode_version}"
  else
    warn "unable to read Xcode version"
  fi
fi

if command -v xcrun >/dev/null 2>&1; then
  simulator_id="$(xcrun simctl list devices available iOS 2>/dev/null | awk -F '[()]' '/iPhone/ { print $2; exit }' || true)"
  if [ -n "${simulator_id}" ]; then
    pass "available iPhone simulator detected"
  else
    warn "no available iPhone simulator found; make test will fail"
  fi
fi

if [ -f ".githooks/pre-commit" ] && [ -x ".githooks/pre-commit" ]; then
  pass "pre-commit hook script is present and executable"
else
  fail "missing or non-executable .githooks/pre-commit"
fi

if git rev-parse --git-dir >/dev/null 2>&1; then
  hooks_path="$(git config --get core.hooksPath || true)"
  if [ "${hooks_path}" = ".githooks" ]; then
    pass "git hooks path is configured to .githooks"
  else
    warn "git hooks path is '${hooks_path:-unset}' (run: make hooks)"
  fi
fi

if [ -f "DeveloperSettings.xcconfig" ]; then
  pass "DeveloperSettings.xcconfig exists"
else
  warn "DeveloperSettings.xcconfig is missing (run: make setup)"
fi

if [ -f "Hadge/Secrets.xcconfig" ]; then
  pass "Hadge/Secrets.xcconfig exists"
else
  warn "Hadge/Secrets.xcconfig is missing (run: make setup)"
fi

if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    pass "gh auth status is valid"
  else
    warn "gh is installed but not authenticated (run: gh auth login)"
  fi
fi

if [ "${failures}" -gt 0 ]; then
  echo "Doctor result: ${failures} failure(s), ${warnings} warning(s)"
  exit 1
fi

echo "Doctor result: 0 failures, ${warnings} warning(s)"
