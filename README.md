# Ledger — Daily Expense Tracker

A single-page web app for tracking your daily expenses, with login and an
open-source Postgres database in the cloud. Export any time to Excel.

**Stack:** plain HTML/CSS/JS (no build step, no framework) + [Supabase](https://supabase.com)
(open-source, Postgres-based backend with built-in auth). This means:
- No server to run or maintain — `index.html` talks directly to Supabase.
- Works by just double-clicking the file locally, or hosted on literally
  any static file host (GitHub Pages, Netlify, Vercel, or your own nginx/Apache).
- Supabase itself is open source (https://github.com/supabase/supabase) and
  can also be self-hosted if you eventually want zero third-party dependency.

---

## 1. Create your database (5 minutes)

1. Go to https://supabase.com, sign up free, and create a new project.
2. Once it's ready, open **SQL Editor** in the left sidebar → **New query**.
3. Paste in the contents of `supabase-setup.sql` (included here) and click **Run**.
   This creates the `expenses` table and locks it down so only the logged-in
   owner of a row can ever read or write it (Row Level Security).
4. Go to **Project Settings → API**. Copy:
   - **Project URL**
   - **anon public** key

By default Supabase requires email confirmation for new sign-ups. For a
personal single-user app you can turn this off to skip the email step:
**Authentication → Providers → Email → toggle off "Confirm email"**.

## 2. Connect the app to your database

Open `index.html` in a text editor and edit these two lines near the top of
the `<script>` section:

```js
const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
```

Paste in the values you copied above. Save the file.

> The anon key is safe to expose in frontend code — it only grants access
> allowed by the Row Level Security policies you set up in step 1, which
> restrict every user to their own rows.

## 3. Run it

**Locally:** just double-click `index.html`, or serve it so browsers are happy
with fetch requests:
```bash
cd expense-tracker
python3 -m http.server 8000
# open http://localhost:8000
```

**On an open-source / free host**, pick any of these (all free tiers, all
just need you to drop `index.html` in):
- **GitHub Pages** — push this folder to a GitHub repo, enable Pages in
  Settings → Pages, done. You get a URL like `you.github.io/expense-tracker`.
- **Netlify / Vercel** — drag-and-drop the folder in their dashboard, or
  connect a GitHub repo for auto-deploys.
- **Your own server** — copy `index.html` into any nginx/Apache/Caddy web
  root. It's a static file, nothing else is required.

## 4. Using the app

1. First visit: click **Create an account**, enter an email + password.
   This is your personal login — nobody else can see your data.
2. Sign in, then use **Add an expense** to log entries (date, amount,
   category, optional note).
3. The **Entries** table lists everything, filterable by month, with
   running totals for "this month" and "all time".
4. **Export to Excel** downloads an `.xlsx` file of everything you've logged
   (or open Supabase's Table Editor and use its own CSV export any time,
   as a second option straight from the database).

## Notes

- Currency is shown as ₹ (INR) — change the `₹` characters in `index.html`
  (search for `₹`) if you'd like a different symbol.
- Categories are a fixed dropdown (Food, Transport, Bills, Shopping, Health,
  Entertainment, Other) — edit the `<select id="exp-category">` list in
  `index.html` to customize.
- Multi-user: the schema already supports it (each row is tied to
  `auth.users`) — just let more people sign up, everyone only ever sees
  their own expenses.
