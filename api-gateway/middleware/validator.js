function detectMaliciousInput(req, res, next) {
    // Decode URL to catch encoded attacks
    const decodedUrl = decodeURIComponent(req.originalUrl);

    const data =
        JSON.stringify(req.body) +
        decodedUrl +
        JSON.stringify(req.query);

    // SQL Injection patterns
    const sqlPatterns = [
        /(\bOR\b|\bAND\b).*=.*/i,
        /('|--|;|DROP|SELECT|INSERT|DELETE|UPDATE)/i
    ];

    // XSS patterns
    const xssPatterns = [
        /<script.*?>.*?<\/script>/i,
        /javascript:/i,
        /onerror=/i,
        /alert\(/i
    ];

    for (let pattern of sqlPatterns) {
        if (pattern.test(data)) {
            console.log("⚠️ SQL ATTACK DETECTED:", data);
            req.logMessage = "Blocked: SQL Injection detected";

            return res.status(400).json({
                message: "Blocked: SQL Injection detected"
            });
        }
    }

    for (let pattern of xssPatterns) {
        if (pattern.test(data)) {
            console.log("⚠️ XSS ATTACK DETECTED:", data);
            req.logMessage = "Blocked: XSS attack detected";
            return res.status(400).json({
                message: "Blocked: XSS attack detected"
            });
        }
    }

    next();
}

module.exports = { detectMaliciousInput };