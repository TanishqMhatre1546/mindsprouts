(() => {
    const tutorSessionId   = window.tutorSessionId   || '';
    const tutorTopicName   = window.tutorTopicName   || 'General Studies';
    const tutorSubjectName = window.tutorSubjectName || 'General';
    const presetQuestionId = window.presetQuestionId || null;

    const chatBox = document.getElementById('tutor-chat-messages');
    const chatForm = document.getElementById('tutor-chat-form');
    const chatInput = document.getElementById('tutor-chat-input');
    const explainButtons = document.querySelectorAll('.explain-btn');
    const newRedemptionBtn = document.getElementById('new-redemption-btn');
    const redemptionForm = document.getElementById('redemption-answer-form');
    const redemptionInput = document.getElementById('redemption-answer-input');
    const ttsToggle = document.getElementById('tutor-tts-toggle');
    let activeRedemptionId = null;
    const conversation = [];
    let ttsEnabled = false;

    if (!chatBox || !chatForm || !chatInput) {
        return;
    }

    if (ttsToggle) {
        ttsToggle.addEventListener('click', () => {
            ttsEnabled = !ttsEnabled;
            ttsToggle.setAttribute('aria-pressed', ttsEnabled ? 'true' : 'false');
            ttsToggle.classList.toggle('btn-warning', ttsEnabled);
            ttsToggle.classList.toggle('btn-light', !ttsEnabled);
            if (!ttsEnabled && window.MindSproutsVoice) {
                window.MindSproutsVoice.stopSpeaking();
            }
        });
    }

    function renderMessageText(text) {
        const escaped = String(text || '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
        return escaped
            .replace(/\n/g, '<br>')
            .replace(/(^|<br>)\- (.+?)(?=<br>|$)/g, '$1• $2');
    }

    function addMessage(role, text) {
        const el = document.createElement('div');
        el.className = `tutor-msg ${role}`;
        el.innerHTML = renderMessageText(text);
        chatBox.appendChild(el);
        chatBox.scrollTop = chatBox.scrollHeight;
        const mappedRole = role === 'assistant' ? 'model' : 'user';
        conversation.push({ role: mappedRole, text });
        if (role === 'assistant' && ttsEnabled && window.MindSproutsVoice) {
            window.MindSproutsVoice.speak(text, { rate: 1, pitch: 1 });
        }
    }

    function buildHistoryPayload() {
        return conversation.map((turn) => ({
            role: turn.role,
            text: turn.text
        }));
    }

    async function askGeminiWithHistory(userMessage) {
        const data = await postJson('/api/ai-tutor/gemini-chat', {
            tutor_session_id: tutorSessionId,
            message: userMessage,
            topic_name: tutorTopicName,
            subject_name: tutorSubjectName,
            history: buildHistoryPayload()
        });
        return data.message;
    }

    async function postJson(url, payload) {
        const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
        const resp = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf },
            body: JSON.stringify(payload)
        });
        const data = await resp.json();
        if (!resp.ok) {
            throw new Error(data.error || 'Request failed');
        }
        return data;
    }

    chatForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const message = chatInput.value.trim();
        if (!message) return;
        const submitBtn = chatForm.querySelector('button[type="submit"]');
        chatInput.disabled = true;
        if (submitBtn) {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';
        }
        addMessage('user', message);
        chatInput.value = '';
        try {
            const reply = await askGeminiWithHistory(message);
            addMessage('assistant', reply);
        } catch (err) {
            addMessage('assistant', `Oops, I could not answer right now. ${err.message}`);
        } finally {
            chatInput.disabled = false;
            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="fa-solid fa-paper-plane"></i>';
            }
            chatInput.focus();
        }
    });

    explainButtons.forEach((btn) => {
        btn.addEventListener('click', async () => {
            const questionId = btn.dataset.questionId;
            btn.disabled = true;
            const originalHtml = btn.innerHTML;
            btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Explaining...';
            try {
                const data = await postJson('/api/ai-tutor/explain', {
                    tutor_session_id: tutorSessionId,
                    question_id: questionId
                });
                addMessage('assistant', data.message);
            } catch (err) {
                addMessage('assistant', `I could not explain that question now. ${err.message}`);
            } finally {
                btn.disabled = false;
                btn.innerHTML = originalHtml;
            }
        });
    });

    if (newRedemptionBtn) {
        newRedemptionBtn.addEventListener('click', async () => {
            try {
                const data = await postJson('/api/ai-tutor/redemption/new', {
                    tutor_session_id: tutorSessionId
                });
                activeRedemptionId = data.redemption_id;
                addMessage('assistant', data.question_text);
                redemptionForm.style.display = 'flex';
                redemptionInput.focus();
            } catch (err) {
                addMessage('assistant', `Could not start challenge. ${err.message}`);
            }
        });
    }

    if (redemptionForm) {
        redemptionForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            if (!activeRedemptionId) return;
            const answer = redemptionInput.value.trim();
            if (!answer) return;
            addMessage('user', answer);
            redemptionInput.value = '';
            try {
                const data = await postJson('/api/ai-tutor/redemption/answer', {
                    tutor_session_id: tutorSessionId,
                    redemption_id: activeRedemptionId,
                    answer
                });
                addMessage('assistant', data.message);
                activeRedemptionId = null;
                redemptionForm.style.display = 'none';
            } catch (err) {
                addMessage('assistant', `Could not check answer. ${err.message}`);
            }
        });
    }

    if (presetQuestionId) {
        const btn = document.querySelector(`.explain-btn[data-question-id="${presetQuestionId}"]`);
        if (btn) btn.click();
    }

    // Seed conversation history from pre-rendered messages.
    // If pre-rendered messages exist, rebuild from DOM and avoid duplicate seeds.
    conversation.length = 0;
    chatBox.querySelectorAll('.tutor-msg').forEach((node) => {
        const isAssistant = node.classList.contains('assistant');
        conversation.push({
            role: isAssistant ? 'model' : 'user',
            text: (node.textContent || '').trim()
        });
    });
})();
