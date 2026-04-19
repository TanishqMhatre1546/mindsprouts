document.addEventListener('DOMContentLoaded', function () {

    const questions    = document.querySelectorAll('.question-block');
    const totalQ       = questions.length;
    let current        = 0;
    let timerInterval  = null;
    let isSubmitting   = false;
    const timerEnabled = document.getElementById('timer-display') !== null;
    const timerDisplay = document.getElementById('timer-display');
    const timerNum = document.getElementById('timer-num');
    const timerProgress = document.getElementById('timer-progress-fill');
    const totalTimerSec = timerDisplay ? parseInt(timerDisplay.dataset.totalTime || '0', 10) : 0;
    const serverRemainingSec = timerDisplay ? parseInt(timerDisplay.dataset.remainingTime || '0', 10) : 0;
    const failedUrl = timerDisplay ? timerDisplay.dataset.failedUrl : '';
    const quizTokenInput = document.querySelector('input[name="quiz_attempt_token"]');
    const quizToken = quizTokenInput ? quizTokenInput.value : '';
    const localTimerKey = quizToken ? `mindsprouts_quiz_started_at_${quizToken}` : null;

    if (questions.length > 0) showQuestion(0);

    function showQuestion(index) {
        questions.forEach((q, i) => {
            q.style.display = i === index ? 'block' : 'none';
        });
        updateProgress(index + 1, totalQ);
        const counter = document.getElementById('q-counter');
        if (counter) counter.textContent = `Question ${index + 1} of ${totalQ}`;
        syncQuestionState(questions[index], index);
        if (timerEnabled) startTimer();
    }

    function updateProgress(cur, total) {
        const bar = document.getElementById('progress-fill');
        if (bar) bar.style.width = ((cur / total) * 100) + '%';
    }

    function startTimer() {
        clearInterval(timerInterval);
        if (!timerDisplay || !timerNum || totalTimerSec <= 0) return;
        let syncedStart = Math.floor(Date.now() / 1000) - Math.max(0, totalTimerSec - serverRemainingSec);
        if (localTimerKey) {
            const savedStart = parseInt(localStorage.getItem(localTimerKey) || '0', 10);
            if (savedStart > 0) {
                syncedStart = savedStart;
            } else {
                localStorage.setItem(localTimerKey, String(syncedStart));
            }
        }

        function updateTimerFrame() {
            const nowSec = Math.floor(Date.now() / 1000);
            const elapsed = Math.max(0, nowSec - syncedStart);
            const timeLeft = Math.max(0, totalTimerSec - elapsed);
            const minutes = String(Math.floor(timeLeft / 60)).padStart(2, '0');
            const seconds = String(timeLeft % 60).padStart(2, '0');
            timerNum.textContent = `${minutes}:${seconds}`;
            const ratio = totalTimerSec > 0 ? (timeLeft / totalTimerSec) : 0;
            if (timerProgress) {
                timerProgress.style.width = `${Math.max(0, Math.min(100, ratio * 100))}%`;
                timerProgress.classList.remove('timer-green', 'timer-yellow', 'timer-red');
                if (ratio > 0.5) timerProgress.classList.add('timer-green');
                else if (ratio >= 0.2) timerProgress.classList.add('timer-yellow');
                else timerProgress.classList.add('timer-red');
            }
            timerDisplay.classList.toggle('danger', ratio < 0.2);

            if (timeLeft <= 0) {
                clearInterval(timerInterval);
                if (localTimerKey) localStorage.removeItem(localTimerKey);
                disableQuizAndFail();
            }
        }

        updateTimerFrame();
        timerInterval = setInterval(function () {
            updateTimerFrame();
        }, 1000);
    }

    function disableQuizAndFail() {
        document.querySelectorAll('.option-btn, .next-btn, .prev-btn').forEach(btn => {
            btn.disabled = true;
        });
        if (failedUrl) {
            window.location.href = failedUrl;
        }
    }

    function moveNext() {
        if (isSubmitting) return;
        clearInterval(timerInterval);
        current++;
        if (current < totalQ) {
            showQuestion(current);
        } else {
            isSubmitting = true;
            document.getElementById('quiz-form').submit();
        }
    }

    function movePrev() {
        if (isSubmitting) return;
        clearInterval(timerInterval);
        if (current > 0) {
            current--;
            showQuestion(current);
        }
    }

    function syncQuestionState(block, index) {
        if (!block) return;
        const qid = block.dataset.qid;
        const hidden = document.getElementById('hidden_' + qid);
        const selected = hidden ? hidden.value : '';
        block.querySelectorAll('.option-btn').forEach(btn => {
            btn.classList.toggle('selected', btn.dataset.option === selected);
        });
        const nextBtn = block.querySelector('.next-btn');
        if (nextBtn) nextBtn.disabled = !selected;
        const prevBtn = block.querySelector('.prev-btn');
        if (prevBtn) prevBtn.disabled = (index === 0);
    }

    // Option selection
    document.querySelectorAll('.option-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            const block = this.closest('.question-block');
            block.querySelectorAll('.option-btn').forEach(b => b.classList.remove('selected'));
            this.classList.add('selected');
            const qid = this.dataset.qid;
            document.getElementById('hidden_' + qid).value = this.dataset.option;
            const nextBtn = block.querySelector('.next-btn');
            if (nextBtn) nextBtn.disabled = false;
        });
    });

    // Next button
    document.querySelectorAll('.next-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            const block  = this.closest('.question-block');
            const qid    = block.dataset.qid;
            const answer = document.getElementById('hidden_' + qid).value;
            if (!answer) {
                alert('Please select an answer first!');
                return;
            }
            moveNext();
        });
    });

    // Previous button
    document.querySelectorAll('.prev-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            movePrev();
        });
    });

    const quizFormEl = document.getElementById('quiz-form');
    if (quizFormEl) {
        quizFormEl.addEventListener('submit', function () {
            if (localTimerKey) localStorage.removeItem(localTimerKey);
        });
    }

    // Add password visibility toggles across all forms
    document.querySelectorAll('input[type="password"]').forEach(input => {
        if (input.closest('.password-toggle-wrap')) return;
        const wrapper = document.createElement('div');
        wrapper.className = 'password-toggle-wrap';
        input.parentNode.insertBefore(wrapper, input);
        wrapper.appendChild(input);
        const toggleBtn = document.createElement('button');
        toggleBtn.type = 'button';
        toggleBtn.className = 'password-toggle-btn';
        toggleBtn.setAttribute('aria-label', 'Show password');
        toggleBtn.innerHTML = '<i class="fa-regular fa-eye"></i>';
        toggleBtn.addEventListener('click', function () {
            const show = input.type === 'password';
            input.type = show ? 'text' : 'password';
            toggleBtn.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
            toggleBtn.innerHTML = show
                ? '<i class="fa-regular fa-eye-slash"></i>'
                : '<i class="fa-regular fa-eye"></i>';
        });
        wrapper.appendChild(toggleBtn);
    });
});
// ── Loading spinner on quiz submit ────────────────
const quizForm = document.getElementById('quiz-form');
if (quizForm) {
    quizForm.addEventListener('submit', function (e) {
        if (quizForm.dataset.submitting === '1') {
            e.preventDefault();
            return;
        }
        quizForm.dataset.submitting = '1';
        const btns = document.querySelectorAll('.next-btn');
        btns.forEach(b => b.classList.add('btn-loading'));
        const prevBtns = document.querySelectorAll('.prev-btn');
        prevBtns.forEach(b => b.disabled = true);
    });
}