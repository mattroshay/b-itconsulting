const STORAGE_KEY = "cookiePreferences";
const STORAGE_VERSION = 1;
const OPTIONAL_KEYS = ["performance", "personalization", "marketing"];

const DEFAULT_PREFERENCES = {
  necessary: true,
  performance: true,
  personalization: true,
  marketing: true
};

const normalizePreferences = (input = {}) => ({
  necessary: true,
  performance: Boolean(input.performance),
  personalization: Boolean(input.personalization),
  marketing: Boolean(input.marketing)
});

const computeConsentLabel = (preferences) => {
  const values = OPTIONAL_KEYS.map((key) => Boolean(preferences[key]));
  if (values.every(Boolean)) return "all";
  if (values.every((value) => !value)) return "essential_only";
  return "custom";
};

const readPreferences = () => {
  if (typeof window === "undefined" || !window.localStorage) return null;

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;

    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object" || !parsed.preferences) return null;

    const preferences = normalizePreferences(parsed.preferences);

    return {
      version: parsed.version || STORAGE_VERSION,
      updatedAt: parsed.updatedAt,
      consent: parsed.consent || computeConsentLabel(preferences),
      preferences
    };
  } catch (error) {
    console.warn("Impossible de lire les préférences de cookies :", error);
    try {
      window.localStorage.removeItem(STORAGE_KEY);
    } catch (_) {
      // ignore inability to remove item
    }
    return null;
  }
};

const writePreferences = (preferences, consent) => {
  const normalized = normalizePreferences(preferences);
  const payload = {
    version: STORAGE_VERSION,
    updatedAt: new Date().toISOString(),
    consent: consent || computeConsentLabel(normalized),
    preferences: normalized
  };

  if (typeof window !== "undefined" && window.localStorage) {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
    } catch (error) {
      console.warn("Impossible d'enregistrer les préférences de cookies :", error);
    }
  }

  return payload;
};

const updateToggleButton = (button, enabled) => {
  if (!button) return;
  const value = Boolean(enabled);
  button.setAttribute("aria-pressed", value ? "true" : "false");
  button.textContent = value ? "On" : "Off";
};

const syncPreviewToggles = (preferences) => {
  const toggles = document.querySelectorAll("[data-cookie-toggle][data-cookie-preview]");
  toggles.forEach((button) => {
    const key = button.dataset.cookieToggle;
    if (!key) return;
    const enabled = preferences && key in preferences ? preferences[key] : DEFAULT_PREFERENCES[key];
    updateToggleButton(button, enabled);
  });
};

const showElement = (element) => {
  if (element) {
    element.removeAttribute("hidden");
  }
};

const hideElement = (element) => {
  if (element && !element.hasAttribute("hidden")) {
    element.setAttribute("hidden", "hidden");
  }
};

const setupCookieConsent = (root) => {
  const banner = root.querySelector("[data-cookie-banner]");
  const modal = root.querySelector("[data-cookie-preferences]");
  const toggleButtons = root.querySelectorAll("[data-cookie-toggle]:not([data-cookie-preview])");
  const triggers = document.querySelectorAll("[data-cookie-preferences-trigger]");
  const acceptButtons = document.querySelectorAll("[data-cookie-accept]");
  const rejectButtons = document.querySelectorAll("[data-cookie-reject]");
  const saveButton = root.querySelector("[data-cookie-save]");
  const closeButtons = root.querySelectorAll("[data-cookie-preferences-close]");

  let stored = readPreferences();
  let working = { ...(stored?.preferences || DEFAULT_PREFERENCES) };
  let bannerWasVisible = false;

  const syncWorkingToggles = () => {
    toggleButtons.forEach((button) => {
      const key = button.dataset.cookieToggle;
      if (!key) return;
      updateToggleButton(button, Boolean(working[key]));
    });
  };

  const refreshFromStored = () => {
    stored = readPreferences();
    working = { ...(stored?.preferences || DEFAULT_PREFERENCES) };
    syncWorkingToggles();
    syncPreviewToggles(stored?.preferences || DEFAULT_PREFERENCES);
    if (stored) {
      hideElement(banner);
    } else {
      showElement(banner);
    }
  };

  const openPreferences = () => {
    if (!modal) return;
    working = { ...(stored?.preferences || DEFAULT_PREFERENCES) };
    syncWorkingToggles();
    bannerWasVisible = banner ? !banner.hasAttribute("hidden") : false;
    hideElement(banner);
    showElement(modal);
    document.body.classList.add("cookie-preferences-open");
  };

  const closePreferences = ({ restore } = { restore: false }) => {
    if (!modal) return;
    hideElement(modal);
    document.body.classList.remove("cookie-preferences-open");

    if (restore) {
      working = { ...(stored?.preferences || DEFAULT_PREFERENCES) };
      syncWorkingToggles();
    }

    if (!stored && bannerWasVisible) {
      showElement(banner);
    }
    bannerWasVisible = false;
  };

  const persistAndClose = (preferences, explicitConsent) => {
    const payload = writePreferences(preferences, explicitConsent);
    stored = payload;
    working = { ...payload.preferences };
    syncWorkingToggles();
    syncPreviewToggles(payload.preferences);
    hideElement(banner);
    closePreferences({ restore: false });
  };

  // Initial state
  syncWorkingToggles();
  syncPreviewToggles(stored?.preferences || DEFAULT_PREFERENCES);
  if (stored) {
    hideElement(banner);
  } else {
    showElement(banner);
  }

  // Event bindings
  toggleButtons.forEach((button) => {
    button.addEventListener("click", () => {
      const key = button.dataset.cookieToggle;
      if (!key || key === "necessary") return;
      working = { ...working, [key]: !working[key] };
      updateToggleButton(button, working[key]);
    });
  });

  triggers.forEach((trigger) => {
    trigger.addEventListener("click", (event) => {
      if (trigger.tagName === "A") {
        event.preventDefault();
      }
      openPreferences();
    });
  });

  acceptButtons.forEach((button) => {
    button.addEventListener("click", () => {
      persistAndClose({
        necessary: true,
        performance: true,
        personalization: true,
        marketing: true
      }, "all");
    });
  });

  rejectButtons.forEach((button) => {
    button.addEventListener("click", () => {
      persistAndClose({
        necessary: true,
        performance: false,
        personalization: false,
        marketing: false
      }, "essential_only");
    });
  });

  saveButton?.addEventListener("click", () => {
    persistAndClose(working, computeConsentLabel(working));
  });

  closeButtons.forEach((button) => {
    button.addEventListener("click", () => {
      closePreferences({ restore: true });
    });
  });

  // Ensure state stays in sync if localStorage changes elsewhere
  window.addEventListener("storage", (event) => {
    if (event.key === STORAGE_KEY) {
      refreshFromStored();
    }
  });
};

const initCookieConsent = () => {
  syncPreviewToggles(readPreferences()?.preferences || DEFAULT_PREFERENCES);

  const root = document.querySelector("[data-cookie-consent]");
  if (!root) return;

  if (root.dataset.cookieConsentInitialized === "true") {
    const stored = readPreferences();
    if (stored) {
      hideElement(root.querySelector("[data-cookie-banner]"));
    } else {
      showElement(root.querySelector("[data-cookie-banner]"));
    }
    syncPreviewToggles(stored?.preferences || DEFAULT_PREFERENCES);
    return;
  }

  root.dataset.cookieConsentInitialized = "true";
  setupCookieConsent(root);
};

export { initCookieConsent };
