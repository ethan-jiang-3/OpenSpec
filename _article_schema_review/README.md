# Article-Driven Schema Review Package

This folder is a review-only draft for using OpenSpec as a content/article production workflow instead of code implementation.

## Included

- `schema.yaml`: proposed `article-driven` schema
- `templates/brief.md`
- `templates/outline.md`
- `templates/research.md`
- `templates/tasks.md`
- `templates/draft.md`
- `templates/edit.md`
- `templates/publish.md`

## Design Choices

- Kept `tasks.md` to stay compatible with current apply/archive behavior.
- Set apply gate to `draft + tasks` so production can start once draft exists and checklist is trackable.
- Added `publish` as final artifact for CMS-ready output packaging.

## How To Test In Project (optional, after review)

1. Copy this schema into project-local schema dir:
   - from: `_article_schema_review/`
   - to: `openspec/schemas/article-driven/`
2. Create a change using it:
   - `openspec new change write-<topic> --schema article-driven`
3. Run workflow:
   - `openspec status --change write-<topic>`
   - `openspec instructions brief --change write-<topic>`
   - `openspec instructions apply --change write-<topic>`

## Known Constraint

`archive` currently checks `tasks.md` by fixed filename in core logic.  
This package intentionally keeps that file name to avoid code changes.
