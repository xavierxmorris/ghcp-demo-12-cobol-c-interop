# Iteration evidence

`reference-run.txt` records a successful run of the pinned container on
3 September 2026. Live output is always written to `build/`; the reference file
is presenter evidence, not a substitute for re-running `.\go.ps1 -Check`.

Generated C includes its generation time and source path, so its SHA-256 changes
between runs even when the maintained COBOL source has not changed. That is one
more reason to treat it as a disposable compiler artifact.
