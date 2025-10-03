const STORAGE_KEY = "cookiePreferences";
const STORAGE_VERSION = 2;
const OPTIONAL_KEYS = ["performance", "personalization", "marketing"];
const CONSENT_TTL_DAYS = 180;
const MS_IN_DAY = 24 * 60 * 60 * 1000;

function daysToMilliseconds(days) {
  return days * MS_IN_DAY;
}

const CONSENT_TTL_MS = daysToMilliseconds(CONSENT_TTL_DAYS);
const DEFAULT_PREFERENCES = {
  necessary: true,
  performance: false,
  personalization: false,
  marketing: false
};

const CATEGORY_HANDLERS = OPTIONAL_KEYS.reduce((acc, key) => {
  acc[key] = new Set();
  return acc;
}, {});

const categoryStates = OPTIONAL_KEYS.reduce((acc, key) => {
  acc[key] = false;
  return acc;
}, {});

let latestPreferences = { ...DEFAULT_PREFERENCES };
let handlersInitialised = false;

const deferredElements = OPTIONAL_KEYS.reduce((acc, key) => {
  acc.set(key, new Set());
  return acc;
}, new Map());

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

const hasConsentExpired = (timestamp) => {
  if (!timestamp) return true;
  const updatedAt = new Date(timestamp);
  if (Number.isNaN(updatedAt.getTime())) return true;
  return Date.now() - updatedAt.getTime() > CONSENT_TTL_MS;
};

const clearStoredPreferences = () => {
  if (typeof window === "undefined" || !window.localStorage) return;

  try {
    window.localStorage.removeItem(STORAGE_KEY);
  } catch (_) {
    // ignore inability to clear storage
  }
};

const runCategoryHandlers = (preferences, { force = false } = {}) => {
  latestPreferences = { ...DEFAULT_PREFERENCES, ...preferences };

  OPTIONAL_KEYS.forEach((category) => {
    const enabled = Boolean(latestPreferences[category]);
    if (!force && enabled === categoryStates[category]) return;

    CATEGORY_HANDLERS[category].forEach((handler) => {
      try {
        if (enabled) {
          handler.enable?.();
        } else {
          handler.disable?.();
        }
      } catch (error) {
        console.error(`Erreur lors de l'exécution du gestionnaire de cookies (${enabled ? 'activation' : 'désactivation'}) pour ${category} :`, error);
      }
    });

    categoryStates[category] = enabled;
  });
};

const registerCookieCategory = (category, handler) => {
  if (!OPTIONAL_KEYS.includes(category)) {
    console.warn(`Catégorie de cookies inconnue : ${category}`);
    return () => {};
  }

  const normalized = typeof handler === "function"
    ? { enable: handler }
    : handler;

  const entry = {
    enable: normalized?.enable,
    disable: normalized?.disable
  };

  CATEGORY_HANDLERS[category].add(entry);

  runCategoryHandlers(latestPreferences, { force: true });

  return () => {
    CATEGORY_HANDLERS[category].delete(entry);
    runCategoryHandlers(latestPreferences, { force: true });
  };
};

const collectDeferredElements = () => {
  deferredElements.forEach((records) => {
    Array.from(records).forEach((record) => {
      if (!record.template.isConnected) {
        record.insertedNodes.forEach((node) => {
          if (node?.parentNode) {
            node.parentNode.removeChild(node);
          }
        });
        record.insertedNodes = [];
        records.delete(record);
      }
    });
  });

  document
    .querySelectorAll("template[data-cookie-category]:not([data-cookie-processed])")
    .forEach((template) => {
      const category = template.dataset.cookieCategory;
      if (!OPTIONAL_KEYS.includes(category)) return;

      template.dataset.cookieProcessed = "true";

      deferredElements.get(category).add({
        template,
        insertedNodes: []
      });
    });
};

const enableDeferredTemplates = (category) => {
  const records = deferredElements.get(category);
  if (!records) return;

  records.forEach((record) => {
    if (!record.template?.parentNode || record.insertedNodes.length) return;

    const fragment = record.template.content.cloneNode(true);
    const clones = Array.from(fragment.childNodes);
    record.template.parentNode.insertBefore(fragment, record.template.nextSibling);
    record.insertedNodes = clones;

    record.insertedNodes = record.insertedNodes.map((node) => {
      if (node.nodeType !== Node.ELEMENT_NODE || node.tagName !== "SCRIPT") {
        return node;
      }

      const replacement = document.createElement("script");
      Array.from(node.attributes).forEach((attr) => {
        if (attr.name === "type" && attr.value === "text/plain") {
          replacement.type = "text/javascript";
        } else {
          replacement.setAttribute(attr.name, attr.value);
        }
      });
      replacement.textContent = node.textContent;
      node.parentNode?.replaceChild(replacement, node);
      return replacement;
    });
  });
};

const disableDeferredTemplates = (category) => {
  const records = deferredElements.get(category);
  if (!records) return;

  records.forEach((record) => {
    if (!record.insertedNodes.length) return;

    record.insertedNodes.forEach((node) => {
      if (node?.parentNode) {
        node.parentNode.removeChild(node);
      }
    });
    record.insertedNodes = [];
  });
};

const readPreferences = () => {
  if (typeof window === "undefined" || !window.localStorage) return null;

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;

    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object" || !parsed.preferences) {
      clearStoredPreferences();
      return null;
    }

    if ((parsed.version || 0) !== STORAGE_VERSION) {
      clearStoredPreferences();
      return null;
    }

    if (hasConsentExpired(parsed.updatedAt)) {
      clearStoredPreferences();
      return null;
    }

    const preferences = normalizePreferences(parsed.preferences);
    const updatedAt = new Date(parsed.updatedAt).toISOString();

    return {
      version: STORAGE_VERSION,
      updatedAt,
      consent: parsed.consent || computeConsentLabel(preferences),
      preferences
    };
  } catch (error) {
    console.warn("Impossible de lire les préférences de cookies :", error);
    clearStoredPreferences();
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
  button.textContent = "";

  const key = button.dataset.cookieToggle;
  const labelBase = button.dataset.cookieLabel
    || (key ? `les cookies ${key}` : "les cookies optionnels");
  const actionLabel = value ? `Désactiver ${labelBase}` : `Activer ${labelBase}`;

  button.setAttribute("aria-label", actionLabel);
  button.setAttribute("title", actionLabel);
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

const setupCookieConsent = (root, initialStored = null) => {
  const banner = root.querySelector("[data-cookie-banner]");
  const modal = root.querySelector("[data-cookie-preferences]");
  const toggleButtons = root.querySelectorAll("[data-cookie-toggle]:not([data-cookie-preview])");
  const triggers = document.querySelectorAll("[data-cookie-preferences-trigger]");
  const acceptButtons = document.querySelectorAll("[data-cookie-accept]");
  const rejectButtons = document.querySelectorAll("[data-cookie-reject]");
  const saveButton = root.querySelector("[data-cookie-save]");
  const closeButtons = root.querySelectorAll("[data-cookie-preferences-close]");

  let stored = initialStored ?? readPreferences();
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
    runCategoryHandlers(stored?.preferences || DEFAULT_PREFERENCES);
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
    runCategoryHandlers(payload.preferences);
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
  collectDeferredElements();

  if (!handlersInitialised) {
    OPTIONAL_KEYS.forEach((category) => {
      registerCookieCategory(category, {
        enable: () => enableDeferredTemplates(category),
        disable: () => disableDeferredTemplates(category)
      });
    });
    handlersInitialised = true;
  }

  const stored = readPreferences();
  const effectivePreferences = stored?.preferences || DEFAULT_PREFERENCES;

  runCategoryHandlers(effectivePreferences, { force: true });
  syncPreviewToggles(effectivePreferences);

  const root = document.querySelector("[data-cookie-consent]");
  if (!root) return;

  if (root.dataset.cookieConsentInitialized === "true") {
    if (stored) {
      hideElement(root.querySelector("[data-cookie-banner]"));
    } else {
      showElement(root.querySelector("[data-cookie-banner]"));
    }
    syncPreviewToggles(effectivePreferences);
    return;
  }

  root.dataset.cookieConsentInitialized = "true";
  setupCookieConsent(root, stored);
};

export { initCookieConsent, registerCookieCategory };
