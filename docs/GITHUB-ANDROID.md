# Build XOS from an Android phone

1. In Chrome on Android open github.com, sign in, and switch to "Desktop site" (Chrome menu). Create a new repository named `xos` (public repos get free Actions minutes).
2. **Add the workflow file.** In the repo: Add file > Create new file. In the name box type `.github/workflows/build-xos.yml` (typing `/` creates folders). Paste the contents of `build-xos.yml` from the download. Commit to `main`.
3. **Add the source.** Add file > Upload files > choose `xos-source.zip` (keep that exact name, in the repo root) > Commit to `main`. The workflow unpacks it itself. Uploading the zip starts a build automatically.
4. **Run manually (any time).** Actions tab > "Build XOS ISO" > Run workflow > Run workflow.
5. A run takes roughly 30-90 minutes. Open the run; if it is green, scroll to **Artifacts**: `XOS-Alpha-amd64-ISO` (ISO + checksum) and `XOS-build-logs` (logs and boot screenshots). If red, open the failed step and send me the last 50 lines of its log.
6. Artifacts download as a .zip. Rufus needs the `.iso`, so download the artifact **on the Windows PC** (same GitHub login) and extract it there, or extract on the phone with the Files app.

To update XOS later: upload a new `xos-source.zip` with the same name (Add file > Upload files replaces it).
