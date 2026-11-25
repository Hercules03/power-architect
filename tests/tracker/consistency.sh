#!/bin/sh
# Drift check for the Tracker docs: the escaping, split-off, base-SHA and go-ahead rules
# have one home each, and phase files name no tracker (Rovo, Jira, Confluence).
# Checks the phrases listed below (a fixed count of matching lines per file set).
# Run from the repo root: sh tests/tracker/consistency.sh (must print: consistency OK).
R=skills/power-architect/references
ALL="$R/tracker.md $R/tracker-jira.md $R/to-spec.md $R/plan.md $R/build.md $R/verify.md $R/finish.md $R/review.md $R/debug.md"
NEUTRAL="$R/tracker.md $R/to-spec.md $R/plan.md $R/build.md $R/verify.md $R/finish.md $R/review.md $R/debug.md"
fail=0
# chk <label> <expected lines> <fixed phrase> <files...>: lines containing the phrase, summed over the files
chk() { l=$1; e=$2; p=$3; shift 3; n=$(cat "$@" | grep -ciF -- "$p"); [ "$n" -eq "$e" ] || { echo "FAIL: $l (expected $e, got $n): $p"; fail=1; }; }
chk "escaping rule only in tracker.md"          1 'a literal ` | `'                                   $ALL
chk "split-off rule only in tracker.md"         1 'is split off at the first unescaped'                 $ALL
chk "base SHA never a branch name: contract"    1 'never the base branch name'                          $R/tracker.md
chk "go-ahead rule only in contract"            1 'waits for their go-ahead'                            $ALL
chk "no adapter names outside the adapter"      0 'Rovo'                                                $NEUTRAL
chk "no Jira outside the adapter"               0 'Jira'                                                $NEUTRAL
chk "no Confluence outside the adapter"         0 'Confluence'                                          $NEUTRAL
[ "$fail" -eq 0 ] && echo "consistency OK"
exit "$fail"
