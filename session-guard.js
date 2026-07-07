/* =========================================================
   Idle session guard — shared by every page.
   After 1 hour with no mouse/keyboard/touch activity, the
   user is signed out and sent back to the sign-in screen,
   even if they leave the tab open, background the app, or
   close and reopen it later.
   ========================================================= */
const IDLE_LIMIT_MS = 60 * 60 * 1000; // 1 hour
const ACTIVITY_KEY = 'ledger_last_activity';

function installIdleGuard(supabaseClient) {
  function recordActivity() {
    localStorage.setItem(ACTIVITY_KEY, Date.now().toString());
  }

  function throttle(fn, waitMs) {
    let last = 0;
    return (...args) => {
      const now = Date.now();
      if (now - last >= waitMs) { last = now; fn(...args); }
    };
  }

  async function checkIdle() {
    const last = parseInt(localStorage.getItem(ACTIVITY_KEY) || '0', 10);
    if (last && Date.now() - last > IDLE_LIMIT_MS) {
      await supabaseClient.auth.signOut();
      const path = window.location.pathname;
      if (!path.endsWith('index.html') && path !== '/' && !path.endsWith('/')) {
        window.location.href = 'index.html';
      }
      return;
    }
    // No stored timestamp yet (first-ever visit) — seed it now.
    if (!last) recordActivity();
  }

  // Check BEFORE wiring up activity listeners, so the check compares against
  // whatever the real last-known activity was — not something we just set.
  checkIdle();

  const throttledRecord = throttle(recordActivity, 5000);
  ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'].forEach(evt => {
    window.addEventListener(evt, throttledRecord, { passive: true });
  });

  // Once a minute while the page stays open and in the foreground.
  setInterval(checkIdle, 60 * 1000);

  // Mobile browsers/PWAs often pause timers while backgrounded, then resume
  // the same page instance rather than reloading it. Re-check the instant
  // the app comes back to the foreground, before any tap can register as
  // "activity" and mask how long it was actually away.
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') checkIdle();
  });
  window.addEventListener('pageshow', () => checkIdle());
}
