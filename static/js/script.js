document.addEventListener('DOMContentLoaded', function () {

    const questions    = document.querySelectorAll('.question-block');
    const totalQ       = questions.length;
    let current        = 0;
    let timerInterval  = null;
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
        clearInterval(timerInterval);
        current++;
        if (current < totalQ) {
            showQuestion(current);
        } else {
            document.getElementById('quiz-form').submit();
        }
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
});
// ── Loading spinner on quiz submit ────────────────
const quizForm = document.getElementById('quiz-form');
if (quizForm) {
    quizForm.addEventListener('submit', function () {
        const btns = document.querySelectorAll('.next-btn');
        btns.forEach(b => b.classList.add('btn-loading'));
    });
}