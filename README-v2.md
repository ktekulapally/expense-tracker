# Ledger v2 — Income, Recurring Expenses & Email Alerts

This adds three things to your existing app:

1. **Income page** — log monthly income, see Income vs Expense net on the Expenses page.
2. **Edit, search, filter, charts** — on the Expenses page.
3. **Recurring expenses with email alerts** — mark something like "Internet bill, due on the 5th," and get an email the day before, automatically, forever.

No existing data is lost. This is all additive to your first version.

---

## 0. Files in this update

```
index.html                              (updated — expenses page)
income.html                             (new)
recurring.html                          (new)
styles.css                              (new — shared styling, used by all 3 pages)
supabase-config.js                      (new — your credentials, in ONE place now)
supabase-migration-v2.sql               (new tables)
functions/send-recurring-alerts/index.ts (new — the Edge Function that sends alerts)
```

**Important:** credentials now live only in `supabase-config.js`, loaded by every
page. You should **delete the old inline `SUPABASE_URL`/`SUPABASE_ANON_KEY`
lines from your old `index.html`** since this new `index.html` gets them from
`supabase-config.js` instead — that's also what prevents the duplicate-variable
issue you hit before, for good.

---

## 1. Run the new database migration

Supabase → **SQL Editor** → paste in `supabase-migration-v2.sql` → **Run**.

This adds three tables (`income`, `recurring_expenses`, `notification_settings`)
plus row-level security so, as before, everything stays private to your own
account.

## 2. Fill in your credentials once

Open `supabase-config.js`, replace the two placeholder lines with your real
Project URL and anon key (same values as before). Save.

## 3. Upload all files to your repo

Delete your **old** `index.html` from the repo, then upload all the files
listed in section 0 (except the `functions/` folder — that one doesn't go to
GitHub Pages, see step 5) to the repo root: **Add file → Upload files**.

Your site now has 3 pages: `/`, `/income.html`, `/recurring.html`, linked via
the tab bar at the top of each.

At this point, everything works **except the actual email sending** — you can
already add recurring expenses and see them listed, the last piece is wiring
up who actually sends the reminder.

---

## 4. Set up Resend (free email sending)

1. Go to https://resend.com → **Sign up** (free tier: 100 emails/day, 3,000/month).
2. Once in the dashboard, go to **API Keys** → **Create API Key** → copy it.
   You'll paste this into Supabase in step 6 — Resend won't show it again.
3. **No domain setup needed** for this use case: Resend's default sender
   `onboarding@resend.dev` can send to *your own account email* without any
   domain verification. Since you're only alerting yourself, that's enough.
   (If you ever want to send to other people, you'd verify your own domain
   in Resend's dashboard — not needed here.)

## 5. Deploy the Edge Function to Supabase

You need the Supabase CLI for this one step (Edge Functions can't be pasted
in via a simple upload the way SQL can).

**Install the CLI** (pick your OS):
```bash
# macOS
brew install supabase/tap/supabase

# Windows (via Scoop)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Linux
curl -fsSL https://raw.githubusercontent.com/supabase/cli/main/install.sh | sh
```

**Log in and link your project:**
```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```
(Your project ref is the subdomain in your Supabase URL, e.g. if your URL is
`https://zmklfmlppceiulaybjga.supabase.co`, the ref is `zmklfmlppceiulaybjga`.)

**Deploy the function** — run this from inside the folder containing
`functions/send-recurring-alerts/index.ts`:
```bash
supabase functions deploy send-recurring-alerts --no-verify-jwt
```
`--no-verify-jwt` is needed because this function is called by a scheduled
cron job, not a logged-in user with a session token.

**Set the secrets it needs:**
```bash
supabase secrets set RESEND_API_KEY=your_resend_api_key_here
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```
Find the service role key at Project Settings → API → `service_role` secret
(different from the `anon` key — this one bypasses RLS, so never put it in
any frontend file, only here).

**Test it manually** before scheduling, to make sure it's wired correctly:
```bash
curl -i -X POST \
  'https://YOUR_PROJECT_REF.functions.supabase.co/send-recurring-alerts' \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```
It should respond with something like `{"sent":0,"message":"Nothing due tomorrow."}`
unless you happen to have a recurring expense due tomorrow, in which case
check your inbox.

## 6. Schedule it to run daily

Supabase → **Database → Extensions** → enable `pg_cron` and `pg_net` (search
for each, toggle on).

Then **SQL Editor** → run this (replace the two placeholders):

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

That's it — every day at 8 AM IST, Supabase checks for anything due tomorrow
and emails you if so.

To change the time later, adjust the cron expression (minute hour * * *, in
UTC) and re-run `select cron.schedule(...)` with the same job name — it
updates in place.

To see if it's actually firing: **Database → Cron Jobs** shows run history,
including any errors.

---

## 7. Using the new features

- **Income page**: log salary/freelance/etc. The Expenses page's "This Month"
  summary now shows Income, Expenses, and Net side by side.
- **Editing**: click the pencil icon on any row (Expenses, Income, or
  Recurring) to load it back into the form above for editing.
- **Search & filters**: on the Expenses page, filter by month, category, or
  free-text search across notes/category.
- **Charts**: a category breakdown (doughnut) reacting to your current
  filters, and a 6-month spending trend, both on the Expenses page. The
  Income page shows a 6-month Income vs Expense bar chart.
- **Recurring & Alerts page**: add things like "Internet — ₹999 — due on the
  5th" once. You'll get an email the day before, every month, with no further
  action needed. Toggle "Active/Paused" to pause a reminder without deleting
  it (e.g. while a subscription is on hold).

## What's next: SMS

The `phone_number` and `sms_enabled` fields already exist in
`notification_settings` and the alerts UI — they're just not wired to
anything yet. When you're ready, the same Edge Function can be extended to
also call Twilio's API for any recurring expense with SMS turned on. Just
say the word and I'll wire that in.
