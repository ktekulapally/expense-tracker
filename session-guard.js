/* =========================================================
   Idle session guard — shared by every page.
   After 1 hour with no mouse/keyboard/touch activity, the
   user is signed out and sent back to the sign-in screen,
   even if they leave the tab open the whole time.
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
      if (!window.location.pathname.endsWith('index.html') && window.location.pathname !== '/' && !window.location.pathname.endsWith('/')) {
        window.location.href = 'index.html';
      }
    }
  }

  // Mark activity now, then on any user interaction (throttled so we're not
  // hitting localStorage on every pixel of mouse movement).
  recordActivity();
  const throttledRecord = throttle(recordActivity, 5000);
  ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'].forEach(evt => {
    window.addEventListener(evt, throttledRecord, { passive: true });
  });

  // Check immediately on load (catches "left the tab closed/idle for hours,
  // came back" case) and then once a minute while the page stays open.
  checkIdle();
  setInterval(checkIdle, 60 * 1000);
}
