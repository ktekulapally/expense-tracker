# Ledger v4 — Stronger themes, single Export menu, 1-hour idle logout

## What changed

1. **Backgrounds now clearly different per page** — and fixed the real cause
   of why v3's colors didn't seem to show up: the stylesheet filename never
   changed, so browsers (and GitHub's CDN) kept serving the cached old copy.
   `styles.css` is now linked as `styles.css?v=2` everywhere, which forces a
   fresh fetch. The themes themselves are also more distinct now:
   - **Expenses**: cool blue-grey with fine horizontal ledger rules.
   - **Income**: soft green with a subtle dot-grid pattern.
   - **Recurring & Alerts**: warm amber with a gentle diagonal hatch.
   Same fonts and brass accent everywhere, so it still reads as one app.

2. **Single "Export" dropdown** on both Expenses and Income — click it, pick
   Excel or PDF. Print stays as its own separate button.

3. **1-hour idle auto-logout**, via a new shared `session-guard.js`:
   - Tracks your last mouse/keyboard/touch activity.
   - If more than 1 hour passes with no activity — whether you left the tab
     open or closed the browser entirely — you're signed out and sent back
     to the sign-in screen the next time the page loads or is checked.
   - Checked immediately on page load and then every minute while the page
     stays open.

   Note on your original observation ("logged in after a new deployment"):
   a fresh deploy doesn't touch your browser's saved session — that's normal
   and unrelated to code changes, sessions persist in your browser until they
   expire or you sign out. The idle timer above is what now makes the app
   ask you to sign in again after enough time has passed, deploy or no
   deploy.

   Want a shorter or longer idle window than 1 hour? Open `session-guard.js`
   and change:
   ```js
   const IDLE_LIMIT_MS = 60 * 60 * 1000; // 1 hour — change the "60" (minutes)
   ```

## Files to upload

```
index.html
income.html
recurring.html
reset-password.html
styles.css
session-guard.js   (new)
```

Upload all of these to your repo root, replacing existing files with the
same names. `session-guard.js` is new, so it'll just be added.

After uploading, do a hard refresh (Ctrl+Shift+R / Cmd+Shift+R) once to make
sure your own browser isn't still holding onto a cached `styles.css` from
before the `?v=2` change existed.
