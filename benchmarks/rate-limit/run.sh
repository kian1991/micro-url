#!/usr/bin/env bash
set -euo pipefail

URL=${1:-http://localhost:3000/health}
DURATION=${2:-10s}
THREADS=${3:-2}
CONNECTIONS=${4:-10}

wrk -t${THREADS} -c${CONNECTIONS} -d${DURATION} -s wrk-report.lua $URL