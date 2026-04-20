document.addEventListener("DOMContentLoaded", function () {
    const root = document.getElementById("game-root");
    if (!root) return;

    const topicId = parseInt(root.dataset.topicId || "0", 10);
    const modeUrl = root.dataset.modeUrl;
    const submitUrl = root.dataset.submitUrl;
    const startedAtSec = Math.floor(Date.now() / 1000);

    function escapeHtml(text) {
        return String(text)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    function finishGame(score, totalItems, extraPayload) {
        const timeSpentSec = Math.max(0, Math.floor(Date.now() / 1000) - startedAtSec);
        const payload = {
            topic_id: topicId,
            score: score,
            total_items: totalItems,
            time_spent_sec: timeSpentSec,
            ...extraPayload,
        };

        fetch(submitUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload),
        })
            .then((resp) => resp.json().then((data) => ({ ok: resp.ok, data })))
            .then(({ ok, data }) => {
                if (!ok) throw new Error(data.error || "Failed to submit game.");
                root.innerHTML = `
                    <h3 class="mb-3"><i class="fa-solid fa-trophy text-warning"></i> Game Complete!</h3>
                    <p class="mb-1"><strong>Score:</strong> ${data.score}/${data.total_items}</p>
                    <p class="mb-1"><strong>Accuracy:</strong> ${data.accuracy}%</p>
                    <p class="mb-3"><strong>Time:</strong> ${data.time_spent_sec}s</p>
                    <div class="alert alert-success mb-3">+${data.points_earned} points added to your profile.</div>
                    <a class="btn-primary-ms" href="/topic/${topicId}/mode">Back to mode selection</a>
                `;
            })
            .catch((err) => {
                root.innerHTML = `<div class="alert alert-danger">${escapeHtml(err.message)}</div>`;
            });
    }

    function renderSorter(gameData) {
        const bins = gameData.bins || [];
        const items = gameData.items || [];
        root.innerHTML = `
            <h3>${escapeHtml(gameData.title || "Sorter")}</h3>
            <p class="text-muted">${escapeHtml(gameData.instruction || "Sort all items correctly.")}</p>
            <div id="sorter-list" class="mb-3"></div>
            <button id="sorter-submit" class="btn-primary-ms">Submit Game</button>
        `;

        const list = root.querySelector("#sorter-list");
        items.forEach((item, idx) => {
            const options = bins
                .map((bin) => `<option value="${escapeHtml(bin)}">${escapeHtml(bin)}</option>`)
                .join("");
            list.insertAdjacentHTML(
                "beforeend",
                `
                <div class="d-flex align-items-center gap-3 mb-2">
                    <div style="min-width:180px;font-weight:700">${escapeHtml(item.label)}</div>
                    <select class="form-select sorter-answer" data-idx="${idx}" style="max-width:220px">
                        <option value="">Choose bin...</option>
                        ${options}
                    </select>
                </div>
                `
            );
        });

        root.querySelector("#sorter-submit").addEventListener("click", function () {
            let score = 0;
            const chosen = [];
            root.querySelectorAll(".sorter-answer").forEach((el) => {
                const idx = parseInt(el.dataset.idx || "0", 10);
                const value = el.value;
                chosen.push({ item: items[idx].label, chosen: value });
                if (value && value === items[idx].answer) score += 1;
            });
            finishGame(score, items.length || 1, { module: "SORTER", answers: chosen });
        });
    }

    function renderRunner(gameData) {
        const correctItems = gameData.correct_items || [];
        const obstacleItems = gameData.obstacle_items || [];
        const allItems = [...correctItems, ...obstacleItems].sort(() => Math.random() - 0.5);
        let score = 0;
        let clickedCount = 0;

        root.innerHTML = `
            <h3>${escapeHtml(gameData.title || "Runner")}</h3>
            <p class="text-muted">${escapeHtml(gameData.instruction || "Tap only the correct targets.")}</p>
            <div class="mb-3"><strong>Progress:</strong> <span id="runner-progress">0/${allItems.length}</span></div>
            <div id="runner-items" class="d-flex flex-wrap gap-2 mb-3"></div>
            <button id="runner-submit" class="btn-primary-ms" disabled>Submit Game</button>
        `;

        const container = root.querySelector("#runner-items");
        allItems.forEach((label) => {
            const button = document.createElement("button");
            button.type = "button";
            button.className = "btn btn-outline-primary";
            button.textContent = label;
            button.addEventListener("click", function () {
                if (button.disabled) return;
                button.disabled = true;
                clickedCount += 1;
                if (correctItems.includes(label)) {
                    score += 1;
                    button.classList.remove("btn-outline-primary");
                    button.classList.add("btn-success");
                } else {
                    button.classList.remove("btn-outline-primary");
                    button.classList.add("btn-danger");
                }
                root.querySelector("#runner-progress").textContent = `${clickedCount}/${allItems.length}`;
                if (clickedCount >= allItems.length) {
                    root.querySelector("#runner-submit").disabled = false;
                }
            });
            container.appendChild(button);
        });

        root.querySelector("#runner-submit").addEventListener("click", function () {
            finishGame(score, correctItems.length || 1, { module: "RUNNER" });
        });
    }

    function renderMatcher(gameData) {
        const pairs = gameData.pairs || [];
        const rightValues = pairs.map((pair) => pair.right).sort(() => Math.random() - 0.5);
        root.innerHTML = `
            <h3>${escapeHtml(gameData.title || "Matcher")}</h3>
            <p class="text-muted">${escapeHtml(gameData.instruction || "Match each left item to the right item.")}</p>
            <div id="matcher-list" class="mb-3"></div>
            <button id="matcher-submit" class="btn-primary-ms">Submit Game</button>
        `;

        const list = root.querySelector("#matcher-list");
        pairs.forEach((pair, idx) => {
            const options = rightValues
                .map((right) => `<option value="${escapeHtml(right)}">${escapeHtml(right)}</option>`)
                .join("");
            list.insertAdjacentHTML(
                "beforeend",
                `
                <div class="d-flex align-items-center gap-3 mb-2">
                    <div style="min-width:200px;font-weight:700">${escapeHtml(pair.left)}</div>
                    <select class="form-select matcher-answer" data-idx="${idx}" style="max-width:260px">
                        <option value="">Select match...</option>
                        ${options}
                    </select>
                </div>
                `
            );
        });

        root.querySelector("#matcher-submit").addEventListener("click", function () {
            let score = 0;
            const chosen = [];
            root.querySelectorAll(".matcher-answer").forEach((el) => {
                const idx = parseInt(el.dataset.idx || "0", 10);
                const value = el.value;
                chosen.push({ left: pairs[idx].left, chosen: value });
                if (value && value === pairs[idx].right) score += 1;
            });
            finishGame(score, pairs.length || 1, { module: "MATCHER", answers: chosen });
        });
    }

    function renderGame(moduleType, gameData) {
        if (moduleType === "SORTER") return renderSorter(gameData);
        if (moduleType === "RUNNER") return renderRunner(gameData);
        if (moduleType === "MATCHER") return renderMatcher(gameData);
        root.innerHTML = `<div class="alert alert-warning">Unsupported game module: ${escapeHtml(moduleType)}</div>`;
    }

    fetch(modeUrl)
        .then((resp) => resp.json().then((data) => ({ ok: resp.ok, data })))
        .then(({ ok, data }) => {
            if (!ok) throw new Error(data.error || "Could not load game.");
            if (data.mode !== "GAMIFY") {
                root.innerHTML = `
                    <div class="alert alert-info mb-3">No gamified level available for this topic.</div>
                    <a class="btn-primary-ms" href="/quiz/${topicId}">Start Standard Quiz</a>
                `;
                return;
            }
            renderGame(data.game_module, data.game_data || {});
        })
        .catch((err) => {
            root.innerHTML = `<div class="alert alert-danger">${escapeHtml(err.message)}</div>`;
        });
});
