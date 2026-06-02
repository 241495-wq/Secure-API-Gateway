const express = require("express");
const cors = require("cors");

const { calculateDREAD, getSTRIDE, getRiskLevel } = require("./analysis");

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.static("public"));

const MAX_LOGS = 2000;
let logs = [];

function aggregateSummary(logs) {
    const total = logs.length;
    const blocked = logs.filter(log => /blocked/i.test(log.message)).length;
    const highRisk = logs.filter(log => log.dread >= 8).length;
    const averageDREAD = total ? Math.round((logs.reduce((sum, log) => sum + (log.dread || 0), 0) / total) * 10) / 10 : 0;

    const users = {};
    const endpoints = {};
    const methods = {};
    const statuses = {};
    const stride = {};

    logs.forEach(log => {
        users[log.user] = (users[log.user] || 0) + 1;
        endpoints[log.url] = (endpoints[log.url] || 0) + 1;
        methods[log.method] = (methods[log.method] || 0) + 1;
        statuses[log.status || 0] = (statuses[log.status || 0] || 0) + 1;
        stride[log.stride] = (stride[log.stride] || 0) + 1;
    });

    const topUsers = Object.entries(users)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([name, count]) => ({ name, count }));

    const topEndpoints = Object.entries(endpoints)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([url, count]) => ({ url, count }));

    return {
        total,
        blocked,
        highRisk,
        averageDREAD,
        topUsers,
        topEndpoints,
        methods,
        statuses,
        stride,
        lastUpdate: new Date().toISOString()
    };
}

app.post("/log", (req, res) => {
    const log = {
        time: req.body.time || new Date().toISOString(),
        method: req.body.method || "UNKNOWN",
        url: req.body.url || "/",
        ip: req.body.ip || "unknown",
        user: req.body.user || "Guest",
        source: req.body.source || "unknown",
        message: req.body.message || "Normal request",
        status: req.body.status || 200
    };

    log.stride = getSTRIDE(log);
    log.dread = calculateDREAD(log);
    log.risk = getRiskLevel(log.dread);

    logs.push(log);
    if (logs.length > MAX_LOGS) logs.shift();

    console.log("📥 LOG RECEIVED:", log);
    res.json({ message: "Log stored" });
});

app.get("/logs", (req, res) => {
    res.json(logs.slice().reverse());
});

app.get("/summary", (req, res) => {
    res.json(aggregateSummary(logs));
});

app.get("/health", (req, res) => {
    res.json({ status: "ok", now: new Date().toISOString() });
});

app.listen(5000, () => {
    console.log("📊 Security Dashboard running on http://localhost:5000");
});
