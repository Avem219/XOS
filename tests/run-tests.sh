#!/usr/bin/env bash
# Repository tests runnable without root or a Linux build host. Boot/desktop tests are NOT covered here (see docs/TESTING.md).
exec "$(dirname "$0")/../scripts/validate.sh" "$@"
