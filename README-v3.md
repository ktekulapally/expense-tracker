# Ledger v3 — Themed pages, password reset, PDF export, mobile layout

## What's new

1. **Per-page color themes** — Expenses stays the original sage/ledger tone,
   Income gets a light green backdrop, Recurring & Alerts gets a warm amber
   one. Same fonts/buttons/accents everywhere, so it still feels like one app.
2. **Password management**:
   - **Forgot password** (when signed out): click "Forgot password?" on the
     sign-in card → emails a reset link → opens `reset-password.html` → set
     a new password.
   - **Change password** (while signed in): new card at the top of the
     Recurring & Alerts page.
3. **PDF export + Print**: "Export to PDF" button next to "Export to Excel"
   on both the Expenses and Income pages, plus a "Print" button that opens
   your browser's print dialog with a clean, button-free printable layout
   (you can "Save as PDF" from that dialog too, if you prefer that over the
   direct PDF export).
4. **Mobile layout**: tables scroll horizontally instead of squashing,
   buttons/filters stack vertically, inputs are sized to avoid the iOS
   auto-zoom-on-focus annoyance, and the header shrinks on small screens.

## Files changed/added

```
index.html            (updated — theme class, PDF/print buttons, forgot-password link)
income.html            (updated — theme class, PDF/print buttons)
recurring.html         (updated — theme class, change-password card)
reset-password.html    (new — completes the forgot-password flow)
styles.css             (updated — themes, print styles, mobile rules)
```

Upload all of these to your repo root (same "Add file → Upload files",
replacing the existing ones with the same names).

## One required setting: allow the reset link to redirect back to your site

Supabase blocks redirect URLs it doesn't recognize, as a security measure.
Without this step, clicking the emailed reset link will fail.

1. Supabase Dashboard → **Authentication → URL Configuration**.
2. Under **Redirect URLs**, add:
   ```
   https://ktekulapally.github.io/expense-tracker/reset-password.html
   ```
3. Save.

That's it — the "Forgot password?" flow will work end to end after that.

## Notes

- Passwords must be at least 6 characters (Supabase's default minimum).
- The PDF export lists every expense/income entry you have (not just the
  currently filtered view) — same as the Excel export.
- Print hides the forms, filters, and charts so you get a clean table of
  entries on paper; use "Export to PDF" instead if you want the same polish
  as a saved file without opening the print dialog.
