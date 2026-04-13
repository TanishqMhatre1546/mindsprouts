document.addEventListener('DOMContentLoaded', function () {

    const questions    = document.querySelectorAll('.question-block');
    const totalQ       = questions.length;
    let current        = 0;
    let timerInterval  = null;
    let isSubmitting   = false;
    const TIMER_SEC = 30;
    const timerEnabled = document.getElementById('timer-display') !== null;

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
        let timeLeft   = TIMER_SEC;
        const numEl    = document.getElementById('timer-num');
        const timerBox = document.getElementById('timer-display');
        if (numEl) numEl.textContent = timeLeft;
        if (timerBox) {
            timerBox.classList.remove('danger');
        }
        timerInterval = setInterval(function () {
            timeLeft--;
            if (numEl) numEl.textContent = timeLeft;
            if (timeLeft <= 5 && timerBox) timerBox.classList.add('danger');
            if (timeLeft <= 0) {
                clearInterval(timerInterval);
                moveNext();
            }
        }, 1000);
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