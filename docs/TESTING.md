# Testing status

Legend: PASS = actually executed and passed, FAIL, NOT RUN.

| Test | Where | Status at time of writing |
|---|---|---|
| Shell syntax, XML, YAML, asset references, package list format, shortcuts, no destructive disk commands | `tests/run-tests.sh` (author's sandbox) | PASS (55 checks) |
| Package availability in Debian trixie | CI step `validate.sh --packages` | NOT RUN (needs CI) |
| ISO build | GitHub Actions | NOT RUN |
| ISO exists, non-empty, SHA-256 verified | CI | NOT RUN |
| QEMU UEFI boot smoke test (non-blank frame + screenshots) | CI `scripts/qemu-smoke.sh` | NOT RUN |
| QEMU legacy BIOS boot | - | NOT RUN (no script yet) |
| Desktop reaches Openbox/Tint2, launcher, file manager, window controls | needs a person or screenshot review | NOT RUN |
| Rufus write (ISO and DD mode) | Windows PC | NOT RUN |
| Physical hardware | - | NOT RUN |
| Persistence | not implemented | NOT RUN |

The QEMU check only proves the VM stayed up and drew something. Review the screenshots in `XOS-build-logs` to confirm what is on screen. Update this table with real results after each build.
