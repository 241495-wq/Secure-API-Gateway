const summaryCards = document.getElementById("summaryCards");
const logTableBody = document.getElementById("logTableBody");
const topUsers = document.getElementById("topUsers");
const topEndpoints = document.getElementById("topEndpoints");
const methodsList = document.getElementById("methodsList");
const strideList = document.getElementById("strideList");
const eventCount = document.getElementById("eventCount");
const statusBadge = document.getElementById("statusBadge");

const searchInput = document.getElementById("searchInput");
const userFilter = document.getElementById("userFilter");
const methodFilter = document.getElementById("methodFilter");
const statusFilter = document.getElementById("statusFilter");
const strideFilter = document.getElementById("strideFilter");
const blockedOnly = document.getElementById("blockedOnly");
const refreshButton = document.getElementById("refreshButton");

let logs = [];
let summary = null;

function formatTime(value) {
    return new Date(value).toLocaleString(undefined, {
        hour12: false,
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit"
    });
}

function toRiskClass(risk) {
    if (risk === "Critical") return "badge-critical";
    if (risk === "High") return "badge-high";
    if (risk === "Medium") return "badge-medium";
    return "badge-low";
}

function renderSummary(data) {
    summaryCards.innerHTML = `
        <div class="summary-card">
            <h3>Total events</h3>
            <p>${data.total}</p>
        </div>
        <div class="summary-card">
            <h3>Blocked / suspicious</h3>
            <p>${data.blocked}</p>
        </div>
        <div class="summary-card">
            <h3>High risk events</h3>
            <p>${data.highRisk}</p>
        </div>
        <div class="summary-card">
            <h3>Average DREAD</h3>
            <p>${data.averageDREAD}</p>
        </div>
    `;
}

function renderLists(data) {
    topUsers.innerHTML = data.topUsers.length
        ? data.topUsers.map(item => `<li><strong>${item.name}</strong> • ${item.count} events</li>`).join("")
        : "<li>No events yet</li>";

    topEndpoints.innerHTML = data.topEndpoints.length
        ? data.topEndpoints.map(item => `<li><strong>${item.url}</strong> • ${item.count} hits</li>`).join("")
        : "<li>No endpoints yet</li>";

    // Methods distribution
    const methodEntries = Object.entries(data.methods || {}).sort((a, b) => b[1] - a[1]);
    methodsList.innerHTML = methodEntries.length
        ? methodEntries.map(([method, count]) => {
            const percent = data.total ? Math.round((count / data.total) * 100) : 0;
            return `<li><strong>${method}</strong> • ${count} requests (${percent}%)</li>`;
        }).join("")
        : "<li>No methods yet</li>";

    // STRIDE distribution
    const strideEntries = Object.entries(data.stride || {}).sort((a, b) => b[1] - a[1]);
    strideList.innerHTML = strideEntries.length
        ? strideEntries.map(([stride, count]) => `<li><strong>${stride}</strong> • ${count} threats</li>`).join("")
        : "<li>No threats yet</li>";
}

function renderFilters(logs) {
    const users = Array.from(new Set(logs.map(item => item.user))).filter(Boolean).sort();
    const methods = Array.from(new Set(logs.map(item => item.method))).filter(Boolean).sort();
    const statuses = Array.from(new Set(logs.map(item => item.status))).filter(Boolean).sort((a,b)=>a-b);
    const strides = Array.from(new Set(logs.map(item => item.stride))).filter(Boolean).sort();

    userFilter.innerHTML = `<option value="">All Users</option>${users.map(user => `<option value="${user}">${user}</option>`).join("")}`;
    methodFilter.innerHTML = `<option value="">All Methods</option>${methods.map(method => `<option value="${method}">${method}</option>`).join("")}`;
    statusFilter.innerHTML = `<option value="">All Statuses</option>${statuses.map(status => `<option value="${status}">${status}</option>`).join("")}`;
    strideFilter.innerHTML = `<option value="">All STRIDE</option>${strides.map(stride => `<option value="${stride}">${stride}</option>`).join("")}`;
}

function renderLogs(logsToRender) {
    eventCount.textContent = `${logsToRender.length} events`;
    logTableBody.innerHTML = logsToRender.map(log => `
        <tr>
            <td>${formatTime(log.time)}</td>
            <td>${log.user}</td>
            <td>${log.method}</td>
            <td>${log.url}</td>
            <td>${log.status}</td>
            <td>${log.message}</td>
            <td>${log.stride}</td>
            <td><span class="cell-badge ${toRiskClass(log.risk)}">${log.risk}</span></td>
            <td>${log.dread}</td>
        </tr>
    `).join("");
}

function applyFilters() {
    const search = searchInput.value.trim().toLowerCase();
    const userValue = userFilter.value;
    const methodValue = methodFilter.value;
    const statusValue = statusFilter.value;
    const strideValue = strideFilter.value;
    const blockedValue = blockedOnly.checked;

    const filtered = logs.filter(log => {
        if (userValue && log.user !== userValue) return false;
        if (methodValue && log.method !== methodValue) return false;
        if (statusValue && String(log.status) !== statusValue) return false;
        if (strideValue && log.stride !== strideValue) return false;
        if (blockedValue && !/blocked|suspicious|no protection|no auth|invalid|access denied/i.test(log.message)) return false;
        if (!search) return true;
        return [log.user, log.url, log.message, log.stride, log.risk, String(log.status)]
            .some(value => String(value).toLowerCase().includes(search));
    });

    renderLogs(filtered);
}

async function loadDashboard() {
    try {
        const [summaryRes, logsRes] = await Promise.all([fetch("/summary"), fetch("/logs")]);
        if (!summaryRes.ok || !logsRes.ok) throw new Error("API fetch failed");

        summary = await summaryRes.json();
        logs = await logsRes.json();

        renderSummary(summary);
        renderLists(summary);
        renderFilters(logs);
        applyFilters();
        statusBadge.textContent = "Connected";
        statusBadge.className = "badge badge-ok";
    } catch (error) {
        statusBadge.textContent = "Offline";
        statusBadge.className = "badge badge-info";
        console.error(error);
    }
}

refreshButton.addEventListener("click", loadDashboard);
searchInput.addEventListener("input", applyFilters);
userFilter.addEventListener("change", applyFilters);
methodFilter.addEventListener("change", applyFilters);
statusFilter.addEventListener("change", applyFilters);
strideFilter.addEventListener("change", applyFilters);
blockedOnly.addEventListener("change", applyFilters);

loadDashboard();
setInterval(loadDashboard, 5000);
