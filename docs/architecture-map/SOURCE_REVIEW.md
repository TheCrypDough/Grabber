# Source review

Snapshot: `178135d0d89eaab4b3b711e309a8e0d29fbf05a0` of https://github.com/TheCrypDough/Grabber; inspected 2026-10-03.

Inspected README, full root AGENTS, package workspace, extension content and background callers, plugin registry, shared schema and Markdown serializer, capture/ingest/search/context/handoff scripts. Extension output is a local browser download; the CLI archives and derives local artifacts. The marketing website is a separate support surface rather than the capture backend. No conversation archives or private transcripts were read. No extension installation, browser account or external upload was performed. Evidence links only this public repository.

## Evidence

- Conversation page: `packages/core-plugins/src/index.ts`
- Extension overlay: `apps/browser-extension/src/entrypoints/content.tsx`
- Content bundle: `packages/core-schema/src/index.ts`
- Markdown serializer: `packages/core-markdown/src/serializer.ts`
- Extension background: `apps/browser-extension/src/entrypoints/background.ts`
- Local Markdown file: `apps/browser-extension/src/entrypoints/background.ts`
- Grabber CLI: `scripts/grabber-capture.sh`, `scripts/grabber-ingest.sh`
- Local archives: `scripts/grabber-find.sh`
- Context and handoff: `scripts/grabber-context.sh`, `scripts/grabber-handoff.sh`

## Limits

This map summarizes principal source seams. The adjacent tracked inventory covers the complete committed file tree. No application code, company authority, customer data, credentials or deployment changed. Generated evidence belongs to this repository only.
