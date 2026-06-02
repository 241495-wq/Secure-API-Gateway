const jwt = require("jsonwebtoken");

const SECRET_KEY = "mysecretkey123";

// Middleware to verify token
function authenticateToken(req, res, next) {
    const authHeader = req.headers["authorization"];

    if (!authHeader) {
        req.logMessage = "Unauthorized: No token provided";
        return res.status(401).json({ message: "No token provided" });
    }

    const token = authHeader.split(" ")[1];

    if (!token) {
        req.logMessage = "Unauthorized: Invalid token format";
        return res.status(401).json({ message: "Invalid token format" });
    }

    jwt.verify(token, SECRET_KEY, (err, user) => {
        if (err) {
            req.logMessage = "Forbidden: Invalid or expired token";
            return res.status(403).json({ message: "Invalid or expired token" });
        }

        req.user = user;
        next();
    });
}

module.exports = { authenticateToken, SECRET_KEY };