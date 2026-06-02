function calculateDREAD(log) {
    let score = 1;
    const message = String(log.message || "").toLowerCase();

    if (message.includes("sql")) score += 8;
    if (message.includes("xss")) score += 7;
    if (message.includes("blocked")) score += 6;
    if (/no auth|no protection|no security|unauthorized/i.test(message)) score += 5;
    if (log.method === "DELETE") score += 4;
    if (log.status >= 400 && log.status < 500) score += 2;
    if (log.status >= 500) score += 3;

    return Math.min(score, 10);
}

function getSTRIDE(log) {
    const message = String(log.message || "").toLowerCase();

    if (message.includes("sql")) return "Tampering";
    if (message.includes("xss")) return "Information Disclosure";
    if (/no auth|no protection|unauthorized/i.test(message)) return "Elevation of Privilege";
    if (log.method === "DELETE") return "Elevation of Privilege";
    if (message.includes("login")) return "Spoofing";
    if (log.method === "GET") return "Information Disclosure";

    return "Normal";
}

function getRiskLevel(dread) {
    if (dread >= 8) return "Critical";
    if (dread >= 6) return "High";
    if (dread >= 4) return "Medium";
    return "Low";
}

module.exports = { calculateDREAD, getSTRIDE, getRiskLevel };