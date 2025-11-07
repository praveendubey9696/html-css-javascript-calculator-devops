// sentry-init.js placeholder: set window.SENTRY_DSN at runtime if you use Sentry
// To enable Sentry: replace the placeholder below with your DSN or inject via server/template.
window.SENTRY_DSN = window.SENTRY_DSN || '';
if (window.SENTRY_DSN) {
  (function(){var s=document.createElement('script');s.src='https://browser.sentry-cdn.com/7.0.0/bundle.min.js';s.crossOrigin='anonymous';document.head.appendChild(s);
  s.onload = function(){ Sentry.init({ dsn: window.SENTRY_DSN }); window.addEventListener('error', e=>Sentry.captureException(e.error||e.message)); }})();
}
