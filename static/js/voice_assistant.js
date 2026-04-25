(() => {
  const SpeechRecognition =
    window.SpeechRecognition || window.webkitSpeechRecognition || null;

  function isSpeechToTextSupported() {
    return Boolean(SpeechRecognition);
  }

  function isTextToSpeechSupported() {
    return Boolean(window.speechSynthesis && window.SpeechSynthesisUtterance);
  }

  function toast(message) {
    const container =
      document.getElementById('voice-toast-container') ||
      (() => {
        const el = document.createElement('div');
        el.id = 'voice-toast-container';
        el.style.cssText =
          'position:fixed;bottom:1rem;left:50%;transform:translateX(-50%);z-index:9999';
        document.body.appendChild(el);
        return el;
      })();
    const toastEl = document.createElement('div');
    toastEl.className = 'toast align-items-center text-bg-warning border-0 show';
    toastEl.setAttribute('role', 'status');
    toastEl.innerHTML = `<div class="d-flex"><div class="toast-body">${String(
      message || ''
    )}</div></div>`;
    container.appendChild(toastEl);
    setTimeout(() => toastEl.remove(), 3500);
  }

  function setBtnState(btn, state) {
    if (!btn) return;
    btn.dataset.voiceState = state;
    btn.classList.toggle('is-listening', state === 'listening');
    const icon = btn.querySelector('i');
    if (!icon) return;
    if (state === 'listening') {
      icon.className = 'fa-solid fa-stop';
      btn.setAttribute('aria-label', 'Stop voice input');
      btn.setAttribute('title', 'Stop');
    } else {
      icon.className = 'fa-solid fa-microphone';
      btn.setAttribute('aria-label', 'Voice input');
      btn.setAttribute('title', 'Speak');
    }
  }

  function startDictation(targetEl, btn) {
    if (!targetEl) return;
    if (!isSpeechToTextSupported()) {
      toast('Voice typing is not supported on this browser. Try Chrome/Edge.');
      return;
    }

    // Toggle off if currently listening
    if (btn && btn._msRecognition) {
      try {
        btn._msRecognition.stop();
      } catch {
        // ignore
      }
      return;
    }

    const recognition = new SpeechRecognition();
    recognition.lang = 'en-US';
    recognition.interimResults = true;
    recognition.continuous = false;
    recognition.maxAlternatives = 1;

    const initial = (targetEl.value || '').trim();
    let committedPrefix = initial ? initial + ' ' : '';

    setBtnState(btn, 'listening');
    btn && (btn._msRecognition = recognition);

    recognition.onresult = (event) => {
      let transcript = '';
      for (let i = event.resultIndex; i < event.results.length; i++) {
        transcript += event.results[i][0].transcript;
      }
      transcript = (transcript || '').trim();
      targetEl.value = (committedPrefix + transcript).trimStart();
      targetEl.dispatchEvent(new Event('input', { bubbles: true }));
    };

    recognition.onerror = () => {
      // Common: "not-allowed" when mic permission denied
      toast('Could not access microphone. Please allow mic permission.');
    };

    recognition.onend = () => {
      if (btn) {
        btn._msRecognition = null;
        setBtnState(btn, 'idle');
      }
      // Keep focus for quick edit
      try {
        targetEl.focus();
      } catch {
        // ignore
      }
    };

    try {
      recognition.start();
    } catch {
      // Some browsers throw if started too quickly
      toast('Voice input could not start. Please try again.');
      btn && (btn._msRecognition = null);
      setBtnState(btn, 'idle');
    }
  }

  function stopSpeaking() {
    if (!isTextToSpeechSupported()) return;
    try {
      window.speechSynthesis.cancel();
    } catch {
      // ignore
    }
  }

  function speak(text, opts = {}) {
    if (!isTextToSpeechSupported()) {
      toast('Text-to-speech is not supported on this browser.');
      return;
    }
    const clean = String(text || '').trim();
    if (!clean) return;

    stopSpeaking();
    const utter = new SpeechSynthesisUtterance(clean);
    utter.rate = typeof opts.rate === 'number' ? opts.rate : 1;
    utter.pitch = typeof opts.pitch === 'number' ? opts.pitch : 1;
    utter.volume = typeof opts.volume === 'number' ? opts.volume : 1;
    if (opts.lang) utter.lang = opts.lang;
    window.speechSynthesis.speak(utter);
  }

  function bindMicButtons(root = document) {
    root.querySelectorAll('[data-voice-target]').forEach((btn) => {
      if (btn.dataset.voiceBound === '1') return;
      btn.dataset.voiceBound = '1';
      setBtnState(btn, 'idle');
      btn.addEventListener('click', () => {
        const selector = btn.getAttribute('data-voice-target');
        const targetEl = selector ? document.querySelector(selector) : null;
        startDictation(targetEl, btn);
      });
    });
  }

  document.addEventListener('DOMContentLoaded', () => {
    bindMicButtons(document);
  });

  window.MindSproutsVoice = {
    isSpeechToTextSupported,
    isTextToSpeechSupported,
    startDictation,
    speak,
    stopSpeaking,
    bindMicButtons
  };
})();

