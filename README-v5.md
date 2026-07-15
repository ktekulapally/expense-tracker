# Ledger v5 — Idle-logout fix, Custom Ledgers, and cleanup

## Fixes

1. **Mobile not signing out after 1 hour** — real bug, not a mobile quirk.
   `session-guard.js` was resetting the "last activity" clock to *right now*
   on every page load, before it ever checked how long you'd actually been
   away — so the check could never fire. Rewritten so the check happens
   first, and also re-checks the instant the app comes back to the
   foreground (mobile browsers often pause timers while backgrounded rather
   than reloading the page, so this catches that case too).

2. **"Change password" removed from Recurring & Alerts** — good catch: on a
   device where you're already signed in and left logged in, anyone with
   access to that browser could otherwise change your password without
   knowing the old one. Password changes now only happen through "Forgot
   password?" on the sign-in screen, which requires access to your email
   inbox — a real barrier the in-app version didn't have.

## New: Custom Ledgers

A fourth section — its own tab, its own page, its own light purple grid
theme — for tracking areas of your life you want to keep entirely separate
from your main Expenses/Income numbers. Examples: Agriculture, Education
(school/college fees), a rental property, a side business.

- **`ledgers.html`** — create a new ledger by name, see a running Income/
  Expense total for each, open one, or delete one (deleting removes every
  entry and category in it — there's a confirmation before that happens).
- **`ledger.html?id=...`** — the actual tracking page for one ledger. Has
  its own Add Expense form, Add Income form, both with full edit/delete,
  search & filters, a category breakdown chart, and its own Export
  (Excel/PDF) and Print.
- **Custom categories per ledger** — the category dropdown on each
  ledger's expense form has a "+ Add new category…" option. Type a name
  once (e.g. "Fertilizer," "Seeds," "Labor" for an Agriculture ledger) and
  it's saved for that ledger going forward.
- **Genuinely separate books** — entries in a custom ledger never appear in
  your main Expenses/Income pages, charts, or totals, and vice versa.

## Also changed

- Expense categories on the main Expenses page (and Recurring & Alerts)
  now include **Fuel**, **Groceries**, and **Adhoc**, alongside the
  existing ones.
- Page title changed from "Ledger" to **"Personal Ledger"** everywhere,
  including the browser tab title and the installed-app name.

## Files to upload

```
index.html              (updated — nav, categories, title, ledger_id filter)
income.html              (updated — nav, title, ledger_id filter)
recurring.html           (updated — nav, title, categories, password section removed)
ledgers.html             (new)
ledger.html              (new)
styles.css               (updated — new theme-ledgers palette/pattern)
session-guard.js         (updated — idle-logout bug fixed)
manifest.json            (updated — app name)
service-worker.js        (updated — cache version bumped, new pages precached)
```

Upload all of these to your repo root (same names replace existing ones;
`ledgers.html` and `ledger.html` are new additions).

## One required database step

Run `supabase-migration-v3-ledgers.sql` in Supabase → SQL Editor before
using the new feature — it adds the `ledgers` and `ledger_categories`
tables and links `expenses`/`income` to them.

## Note on the service worker update

Since `CACHE_NAME` changed (`ledger-shell-v1` → `v2`), anyone who already
installed the app on their phone will automatically get the new files the
next time they open it with a connection — the old cache is cleaned up
automatically, no reinstall needed.
