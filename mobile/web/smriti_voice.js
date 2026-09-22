/**
 * SmritiSetu Web Speech Synthesis Bridge
 * Provides multi-lingual text-to-speech utilizing the browser SpeechSynthesis API.
 * Supports all 14 Indian languages with intelligent phonetic fallbacks.
 */
(function () {
  'use strict';

  var cachedVoices = [];

  function loadVoices() {
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      try {
        cachedVoices = window.speechSynthesis.getVoices() || [];
      } catch (e) {
        console.warn('[SmritiVoice] Error reading system voices:', e);
      }
    }
  }

  if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
    loadVoices();
    if (window.speechSynthesis.onvoiceschanged !== undefined) {
      window.speechSynthesis.onvoiceschanged = loadVoices;
    }
  }

  // Language mapping dictionary with fallback priorities
  var languageFallbackMap = {
    'as': ['as-IN', 'as', 'bn-IN', 'bn', 'hi-IN', 'hi', 'en-IN'],
    'mni': ['mni-IN', 'mni', 'bn-IN', 'bn', 'hi-IN', 'hi', 'en-IN'],
    'bn': ['bn-IN', 'bn-BD', 'bn', 'hi-IN', 'en-IN'],
    'hi': ['hi-IN', 'hi', 'en-IN'],
    'or': ['or-IN', 'or', 'bn-IN', 'hi-IN', 'en-IN'],
    'te': ['te-IN', 'te', 'hi-IN', 'en-IN'],
    'ta': ['ta-IN', 'ta-LK', 'ta', 'en-IN'],
    'kn': ['kn-IN', 'kn', 'hi-IN', 'en-IN'],
    'ml': ['ml-IN', 'ml', 'en-IN'],
    'mr': ['mr-IN', 'mr', 'hi-IN', 'en-IN'],
    'gu': ['gu-IN', 'gu', 'hi-IN', 'en-IN'],
    'pa': ['pa-IN', 'pa-PK', 'pa', 'hi-IN', 'en-IN'],
    'ur': ['ur-IN', 'ur-PK', 'ur', 'hi-IN', 'en-IN'],
    'en': ['en-IN', 'en-GB', 'en-US', 'en'],
    'es': ['es-ES', 'es-MX', 'es'],
    'fr': ['fr-FR', 'fr-CA', 'fr'],
    'de': ['de-DE', 'de'],
    'ar': ['ar-SA', 'ar-EG', 'ar'],
    'zh': ['zh-CN', 'zh-TW', 'zh'],
    'ja': ['ja-JP', 'ja'],
    'ko': ['ko-KR', 'ko']
  };

  function findBestVoice(langCode) {
    if (!cachedVoices || cachedVoices.length === 0) {
      loadVoices();
    }
    if (!cachedVoices || cachedVoices.length === 0) {
      return null;
    }

    var code = (langCode || 'en').toLowerCase().trim();
    var targetLocales = languageFallbackMap[code] || [code, 'en-IN', 'en-US', 'en'];

    for (var i = 0; i < targetLocales.length; i++) {
      var target = targetLocales[i].toLowerCase();
      for (var v = 0; v < cachedVoices.length; v++) {
        var voice = cachedVoices[v];
        if (!voice || !voice.lang) continue;
        var voiceLang = voice.lang.toLowerCase().replace('_', '-');
        if (voiceLang === target || voiceLang.indexOf(target) === 0) {
          return voice;
        }
      }
    }

    // Default to the first voice or English if available
    for (var j = 0; j < cachedVoices.length; j++) {
      if (cachedVoices[j].lang && cachedVoices[j].lang.toLowerCase().indexOf('en') === 0) {
        return cachedVoices[j];
      }
    }

    return cachedVoices[0] || null;
  }

  window.smritiVoice = {
    isAvailable: function () {
      return typeof window !== 'undefined' && 'speechSynthesis' in window;
    },

    isSpeaking: function () {
      if (!this.isAvailable()) return false;
      return window.speechSynthesis.speaking;
    },

    stop: function () {
      if (!this.isAvailable()) return;
      try {
        window.speechSynthesis.cancel();
      } catch (e) {
        console.warn('[SmritiVoice] Cancel error:', e);
      }
    },

    speak: function (text, langCode, rate, volume) {
      if (!this.isAvailable()) {
        console.warn('[SmritiVoice] SpeechSynthesis not supported in this environment.');
        return false;
      }

      if (!text || !text.trim()) {
        return true;
      }

      var cleanText = text.trim();
      var lang = (langCode || 'en').toLowerCase();
      var speechRate = typeof rate === 'number' && rate > 0 ? rate : 0.88;
      var speechVolume = typeof volume === 'number' && volume >= 0 ? volume : 1.0;

      try {
        // Cancel any pending speech before starting new speech
        window.speechSynthesis.cancel();

        var utterance = new SpeechSynthesisUtterance(cleanText);
        utterance.rate = speechRate;
        utterance.volume = speechVolume;

        var selectedVoice = findBestVoice(lang);
        if (selectedVoice) {
          utterance.voice = selectedVoice;
          utterance.lang = selectedVoice.lang;
        } else {
          utterance.lang = lang === 'en' ? 'en-IN' : lang;
        }

        utterance.onerror = function (event) {
          console.warn('[SmritiVoice] Speech synthesis error:', event.error);
        };

        window.speechSynthesis.speak(utterance);
        return true;
      } catch (err) {
        console.error('[SmritiVoice] Failed to execute speak:', err);
        return false;
      }
    }
  };

  console.log('[SmritiVoice] Web Speech Synthesis Engine initialized successfully.');
})();
