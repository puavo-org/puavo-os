export interface ErrorTranslations {
  'error.title': string;
  'error.message': string;
  'error.retry': string;
  'error.exit': string;
  'error.loading': string;
  'error.exiting': string;
}

export interface Translations {
  error: ErrorTranslations;
}

export const TRANSLATIONS: { [locale: string]: Translations } = {
  en: {
    error: {
      'error.title': 'Connection Failed',
      'error.message':
        'Unable to load the requested page. Please check your connection and try again.',
      'error.retry': 'Try Again',
      'error.exit': 'Exit Exam',
      'error.loading': 'Loading...',
      'error.exiting': 'Exiting...',
    },
  },
  fi: {
    error: {
      'error.title': 'Yhteys epäonnistui',
      'error.message':
        'Sivun lataaminen epäonnistui. Tarkista yhteytesi ja yritä uudelleen.',
      'error.retry': 'Yritä uudelleen',
      'error.exit': 'Poistu kokeesta',
      'error.loading': 'Ladataan...',
      'error.exiting': 'Poistutaan...',
    },
  },
  sv: {
    error: {
      'error.title': 'Anslutning misslyckades',
      'error.message':
        'Kunde inte ladda den begärda sidan. Kontrollera din anslutning och försök igen.',
      'error.retry': 'Försök igen',
      'error.exit': 'Avsluta tentamen',
      'error.loading': 'Laddar...',
      'error.exiting': 'Avslutar...',
    },
  },
  de: {
    error: {
      'error.title': 'Verbindung fehlgeschlagen',
      'error.message':
        'Die angeforderte Seite konnte nicht geladen werden. Überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.',
      'error.retry': 'Erneut versuchen',
      'error.exit': 'Prüfung beenden',
      'error.loading': 'Wird geladen...',
      'error.exiting': 'Wird beendet...',
    },
  },
};

export const DEFAULT_LOCALE = 'en';

export function detectLocale(): string {
  const urlParameters = new URLSearchParams(window.location.search);
  const urlLocale = urlParameters.get('locale');

  if (urlLocale && urlLocale in TRANSLATIONS) {
    return urlLocale;
  }

  return DEFAULT_LOCALE;
}

export function getTranslations(): Translations {
  const locale = detectLocale();
  return TRANSLATIONS[locale] || TRANSLATIONS[DEFAULT_LOCALE]!;
}
