# Validation Reports

This folder stores machine-readable and human-readable validation results from:

```bash
./scripts/grabber-validate.sh
```

Generated layout:

```text
reports/
  latest -> runs/<timestamp>/
  runs/
    <timestamp>/
      SUMMARY.md
      summary.json
      results.tsv
      *.log
```

Notes:
- `runs/*` is gitignored.
- Each run is timestamped in UTC.
- `latest` always points to the newest run.
- Use this for debugging, CI traces, and agent health checks.
