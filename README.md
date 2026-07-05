# Ledger — Personal Expense & Income Tracker

A private, single-user (expandable to multi-user) money tracker: log daily
expenses and monthly income, set up recurring bills with automatic email
reminders, see charts, export to Excel or PDF, and it's all yours — no
subscription, no ads, running on free/open-source infrastructure you control.

This README covers everything from a completely fresh setup through every
feature that's been added. It supersedes all the earlier README files
(README.md, README-v2.md, README-v3.md, README-v4.md) — this one file has
the full story.

---

## 1. What this is, technically

- **Frontend**: plain HTML/CSS/JS, no build step, no framework. Three pages:
  `index.html` (Expenses), `income.html` (Income), `recurring.html`
  (Recurring & Alerts), plus `reset-password.html` for password recovery.
- **Backend**: [Supabase](https://supabase.com) — an open-source,
  Postgres-based backend with built-in authentication. There's no server you
  run yourself; the static pages talk directly to your own Supabase project.
- **Hosting**: GitHub Pages (or any static host — Netlify, Vercel, your own
  nginx box, or just opening the file locally).
- **Email alerts**: a Supabase Edge Function + [Resend](https://resend.com)
  (free tier), scheduled with `pg_cron`.

Nothing here costs money at the scale one person needs (Supabase free tier,
Resend free tier, GitHub Pages free hosting).

---

## 2. Full feature list

**Expenses page**
- Add, edit, delete expense entries (date, amount, category, note)
- Search by note/category, filter by category and month
- Category breakdown chart (doughnut) and 6-month spending trend chart
- "This month" stats: Expenses, Income, and Net, side by side
- Optionally mark a new expense as recurring right from the add form
- Export to Excel or PDF (single "Export" dropdown), plus a Print button

**Income page**
- Add, edit, delete income entries (date, amount, source, note)
- This month / all-time income totals
- 6-month Income vs Expenses comparison chart
- Same Export dropdown (Excel/PDF) and Print button

**Recurring & Alerts page**
- Define recurring expenses ("Internet — ₹999 — due on the 5th")
- Toggle each one Active/Paused without deleting it
- Automatic email reminder the day before each payment is due
- Change your alert email address
- Change your account password
- (Phone number field is present for a future SMS option — not active yet)

**Account & security**
- Email/password sign-up and sign-in (Supabase Auth)
- "Forgot password?" flow (emailed reset link → set new password)
- Change password while signed in
- Automatic sign-out after 1 hour of inactivity

**Look & feel**
- Each page has its own light background color and subtle pattern (blue-grey
  ledger lines for Expenses, green dot-grid for Income, amber diagonal hatch
  for Recurring & Alerts) so it's clear which section you're in
- Mobile-friendly: tables scroll horizontally, forms stack, inputs sized to
  avoid iOS auto-zoom

---

## 3. File list (final)

```
index.html                                 Expenses page
income.html                                 Income page
recurring.html                              Recurring & Alerts + settings page
reset-password.html                         Completes the forgot-password flow
styles.css                                  Shared styling for all pages
supabase-config.js                          Your Supabase URL + anon key (edit once)
session-guard.js                            1-hour idle auto-logout, shared by all pages
manifest.json                               Makes the app installable on Android/iOS
service-worker.js                           Lets the installed app load reliably offline
icons/icon-192.png, icon-512.png,
icons/icon-512-maskable.png                 App icons for the home-screen install
supabase-schema-full.sql                    Full database schema (run once, fresh setup)
functions/send-recurring-alerts/index.ts    Edge Function that emails reminders
```

If you're setting this up for the first time, you only need the files above.

---

## 4. First-time setup, start to finish

### 4.1 Create your Supabase project

1. Go to https://supabase.com → sign up free → **New project**.
2. Once ready, open **SQL Editor** → **New query**.
3. Paste in the entire contents of `supabase-schema-full.sql` → **Run**.
   This creates every table (expenses, income, recurring_expenses,
   notification_settings) with Row Level Security already locked down so
   only you can ever see your own rows.
4. Go to **Project Settings → API**. Copy the **Project URL** and the
   **anon public** key — you'll need both in the next step.
5. (Recommended for a personal single-user app) **Authentication →
   Providers → Email** → turn **off** "Confirm email", so sign-up doesn't
   require clicking an email confirmation link.

### 4.2 Add your credentials — in one place

Open `supabase-config.js` and replace the placeholders:
```js
const SUPABASE_URL = "https://your-project-ref.supabase.co";
const SUPABASE_ANON_KEY = "your-anon-key-here";
```
Every page loads this same file, so you only ever edit credentials here —
this is also what prevents the "duplicate variable declaration" error some
early versions of this app hit.

### 4.3 Put it on GitHub Pages

1. Create a **public** GitHub repository (e.g. `expense-tracker`).
2. Upload every file from the list in section 3 to the **repo root** —
   not inside a subfolder. This matters: GitHub Pages only serves
   `index.html` if it's sitting directly at the root.
3. Repo → **Settings → Pages** → **Source: Deploy from a branch** → branch
   `main`, folder `/ (root)` → Save.
4. Wait ~1 minute, then visit `https://yourusername.github.io/your-repo-name/`.
5. Sign up with your own email/password on the page that loads — that's
   your personal login for the app.

### 4.4 If something goes wrong at this stage

These are real issues that came up while setting this app up — quick fixes:

- **"404 File not found"** → `index.html` isn't at the repo root. Check the
  repo's file listing; if it's inside a folder, move it out (delete + re-
  upload at root), or check Settings → Pages is pointed at the right branch.
- **Page shows your README instead of the app** → GitHub Pages falls back
  to rendering `README.md` when there's no `index.html` at the root. Same
  fix as above — get `index.html` onto the root.
- **Console error: "Identifier 'supabase' has already been declared"** →
  this happened when credentials were duplicated by hand-editing in
  GitHub's web editor. It's now avoided entirely because credentials live
  only in `supabase-config.js`. If you ever hand-edit a file in GitHub's
  editor, only change the specific line you need — don't select-all and
  re-paste a whole file, since that's what caused the duplication before.
- **Deployment fails with "Deployment failed, try again later"** → this is
  a transient GitHub infrastructure hiccup, not a problem with your files.
  Go to the **Actions** tab → open the failed run → **Re-run failed jobs**.
  If that doesn't help, wait a few minutes and commit any trivial change to
  trigger a fresh deploy attempt.
- **CSS/background changes don't seem to show up** → almost always a caching
  issue (browser or GitHub's CDN holding an old copy). This app links its
  stylesheet as `styles.css?v=2` specifically to force a fresh fetch when
  the file changes — if you edit `styles.css` again later, bump that number
  (`?v=3`, etc.) and hard-refresh (`Ctrl+Shift+R` / `Cmd+Shift+R`).
- **Sign-in/sign-up does nothing, no visible error** → open DevTools
  (`F12`) → Console tab, and try again — the real error (wrong credentials,
  RLS issue, etc.) will show there. Also check whether "Confirm email" is
  on in Supabase (see 4.1 step 5) — if so, check your inbox for a
  confirmation link before your first sign-in will work.

---

## 5. Setting up email alerts for recurring expenses (optional)

This part is optional — everything else in the app works without it. Do
this whenever you're ready for automatic "due tomorrow" email reminders.

### 5.1 Sign up for Resend

1. Go to https://resend.com → sign up free (100 emails/day, 3,000/month).
2. **API Keys** → **Create API Key** → copy it (shown once).
3. No domain setup needed: Resend's default sender `onboarding@resend.dev`
   can send to your own account email without domain verification — exactly
   what a single-user reminder app needs.

### 5.2 Deploy the Edge Function

This one step needs the Supabase CLI (Edge Functions can't be pasted in
through the dashboard the way SQL can).

```bash
# Install the CLI
brew install supabase/tap/supabase        # macOS
# or: scoop install supabase              # Windows, after adding the bucket
# or: curl -fsSL https://raw.githubusercontent.com/supabase/cli/main/install.sh | sh   # Linux

# Log in and link your project (project ref = the subdomain in your Supabase URL)
supabase login
supabase link --project-ref YOUR_PROJECT_REF

# Deploy (run from the folder containing functions/send-recurring-alerts/index.ts)
supabase functions deploy send-recurring-alerts --no-verify-jwt
```

Set the secrets it needs:
```bash
supabase secrets set RESEND_API_KEY=your_resend_api_key_here
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```
(Service role key is at Project Settings → API — different from the anon
key. It bypasses RLS, so it only ever goes here, never in any frontend file.)

Test it manually:
```bash
curl -i -X POST \
  'https://YOUR_PROJECT_REF.functions.supabase.co/send-recurring-alerts' \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```
Expect `{"sent":0,"message":"Nothing due tomorrow."}` unless something is
actually due tomorrow, in which case check your inbox.

### 5.3 Schedule it to run daily

Supabase → **Database → Extensions** → enable `pg_cron` and `pg_net`.

Then **SQL Editor**:
```sql
select cron.schedule(
  'daily-recurring-alerts',
  '30 2 * * *',  -- 2:30 AM UTC = 8:00 AM IST
  $$
  select net.http_post(
    url := 'https://YOUR_PROJECT_REF.functions.supabase.co/send-recurring-alerts',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_ANON_KEY'
    ),
    body := jsonb_build_object('trigger', 'cron')
  );
  $$
);
```
Adjust the time (minute hour, in UTC) if you want alerts at a different
hour. Check **Database → Cron Jobs** to see run history / errors.

---

## 6. Password reset — one required Supabase setting

For the "Forgot password?" emailed link to work, Supabase needs to know
your site is allowed to be a redirect target:

Supabase → **Authentication → URL Configuration** → under **Redirect
URLs**, add:
```
https://yourusername.github.io/your-repo-name/reset-password.html
```

Without this, the reset email link will fail when clicked.

---

## 7. Using the app day to day

- **Add an expense**: Expenses page → fill the form → optionally tick "Also
  set this up as a monthly recurring expense" to create a reminder at the
  same time.
- **Edit anything**: click the pencil icon on any row (works the same on
  Expenses, Income, and Recurring).
- **Find something**: use the search box and category/month filters on the
  Expenses page.
- **See the big picture**: charts update live with whatever filters are set.
- **Get a file to keep**: click **Export ▾** → Excel or PDF. Use **Print**
  if you just want a paper copy or to "Save as PDF" via your browser's own
  print dialog instead.
- **Manage recurring bills**: Recurring & Alerts page → add once, it emails
  you every month automatically. Toggle Active/Paused to pause without
  deleting (e.g. a subscription on hold).
- **Change alert email or password**: both are on the Recurring & Alerts
  page.
- **Forgot your password**: click "Forgot password?" on the sign-in screen.
- **Automatic sign-out**: after 1 hour of no activity, you'll be asked to
  sign in again next time the app checks (immediately on load, and every
  minute while a page is open). To change that duration, edit
  `session-guard.js`:
  ```js
  const IDLE_LIMIT_MS = 60 * 60 * 1000; // 1 hour — change the 60 (minutes)
  ```

---

## 8. Customizing

- **Currency symbol**: search each `.html` file for `₹` and replace.
- **Expense/income categories**: edit the `<select>` option lists in
  `index.html` (`#exp-category`), `recurring.html` (`#rec-category`), and
  `income.html` (`#inc-source`).
- **Colors/patterns per page**: edit the `body.theme-*` blocks near the top
  of `styles.css`.
- **Idle logout duration**: `IDLE_LIMIT_MS` in `session-guard.js`.

---

## 9. What's not built yet

- **SMS alerts**: the `phone_number` and `sms_enabled` fields already exist
  in the database and the settings UI, just not wired to a provider yet.
  Adding Twilio to the existing Edge Function is a relatively small next
  step whenever you want it.
- **Multi-user**: the schema already supports more than one person (every
  row is tied to `auth.users`), it would just mean letting more people sign
  up — no schema changes needed.

## 10. Installing it as an app on Android

The site is already set up as a **Progressive Web App (PWA)** — no separate
build, no app store needed. Once it's deployed with `manifest.json`,
`service-worker.js`, and the `icons/` folder uploaded alongside everything
else:

1. Open the site in **Chrome on Android**.
2. Tap the **⋮** menu (top right) → **"Install app"** (or **"Add to Home
   screen"**, wording varies by Chrome version). Chrome may also show this
   as an automatic banner/prompt after you've visited a couple of times.
3. Confirm — it installs with the ledger-book icon, and opens full-screen
   from your home screen/app drawer, with no browser address bar. It looks
   and behaves like any other installed app.

Everything works exactly the same once installed — same login, same data,
same Supabase backend. Signing out, editing entries, exporting PDFs, all of
it, since it's the same app, just launched differently.

**If Chrome doesn't offer the install option:**
- Make sure `manifest.json`, `service-worker.js`, and the `icons/` folder
  were actually uploaded to the repo root (not skipped).
- Reload the page once after uploading — the service worker needs one visit
  to register before Chrome will offer to install.
- Confirm you're on `https://` (GitHub Pages always is) — PWAs require it.

**Going further — a real Play Store listing (optional, more involved):**
If you ever want this listed in the Play Store rather than just installed
from the browser, that's a separate step called wrapping it as a **Trusted
Web Activity (TWA)** using Google's `bubblewrap` CLI. It needs an Android
signing key, a Google Play Console account ($25 one-time), and a small
`assetlinks.json` file added to your site to prove you own it. Everything
built here already meets the technical requirements for that path — it's
just an additional packaging step on top, not a rebuild. Say the word if you
want to go down that road later.

