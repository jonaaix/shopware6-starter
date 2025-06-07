/**
 * This script manages user preferred language selection and redirection
 * based on the language set in the URL path.
 * It checks the user's preferred language stored in a cookie,
 * and if it differs from the current language,
 * it simulates a click on the corresponding language button.
 * It also sets the preferred language cookie when a user selects a language.
 */
(() => {
   function getCookie(name) {
      return document.cookie
         .split('; ')
         .find((row) => row.startsWith(name + '='))
         ?.split('=')[1];
   }

   function setCookie(name, value, days) {
      const expires = new Date(Date.now() + days * 86400e3).toUTCString();
      document.cookie = `${name}=${value}; path=/; expires=${expires}; SameSite=Lax`;
   }

   function getCurrentLangFromPath() {
      const path = window.location.pathname;
      const firstSegment = path.split('/')[1] || '';
      return /^[a-z]{2}$/.test(firstSegment) ? firstSegment : 'en';
   }

   function clickPreferredLanguageButton(lang) {
      document.addEventListener('DOMContentLoaded', () => {
         const buttons = document.querySelectorAll('.language-form button[name="languageId"]');

         buttons.forEach(button => {
            const span = button.querySelector('span.language-flag');
            if (!span) return;

            const langClass = Array.from(span.classList).find(cls => cls.startsWith('language-') && cls.length === 11);
            if (!langClass) return;

            const langPrefix = langClass.split('-')[1];
            if (langPrefix === lang) {
               button.click();
            }
         });
      });
   }

   const isBot = /bot|crawl|slurp|spider|mediapartners/i.test(navigator.userAgent);
   if (isBot) return;

   const currentLang = getCurrentLangFromPath();
   const preferredLang = getCookie('userPreferredLanguage');

   if (!preferredLang) {
      setCookie('userPreferredLanguage', currentLang, 365);
      return;
   }

   if (preferredLang !== currentLang) {
      clickPreferredLanguageButton(preferredLang);
   }

   document.addEventListener('DOMContentLoaded', () => {
      document.querySelectorAll('.language-form button[name="languageId"]').forEach(button => {
         button.addEventListener('click', () => {
            const span = button.querySelector('span.language-flag');
            if (!span) return;

            const langClass = Array.from(span.classList).find(cls => cls.startsWith('language-') && cls.length === 11);
            if (!langClass) return;

            const langPrefix = langClass.split('-')[1];
            if (langPrefix) {
               setCookie('userPreferredLanguage', langPrefix, 365);
            }
         });
      });
   });
})();
