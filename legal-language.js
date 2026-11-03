(() => {
  // Legal documents are separate pages, so switching the surrounding UI alone
  // would leave the legal text in the previous language.
  const path = location.pathname;
  const mirror = /\/privacy-policy\/(?:index\.html)?$/.test(path);
  const match = path.match(/\/(privacy|terms)(?:-(de|fr|it|ja))?\.html$/);
  if (!mirror && !match) return;
  const kind = mirror ? 'privacy' : match[1];
  const pageLanguage = mirror ? 'en' : (match[2] || 'en');
  const prefix = mirror ? '../' : '';
  const supported = ['en', 'de', 'fr', 'it', 'ja'];
  const target = language => prefix + kind + (language === 'en' ? '' : '-' + language) + '.html';

  if (pageLanguage !== 'en') {
    localStorage.setItem('lang', pageLanguage);
  } else {
    const preferred = (localStorage.getItem('lang') || navigator.language || 'en').slice(0, 2).toLowerCase();
    if (supported.includes(preferred) && preferred !== 'en') {
      location.replace(target(preferred));
      return;
    }
  }
  document.addEventListener('click', event => {
    const button = event.target.closest('.dropdown-item[data-lang]');
    const language = button?.dataset.lang;
    if (!supported.includes(language)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    localStorage.setItem('lang', language);
    location.href = target(language);
  }, true);
})();
