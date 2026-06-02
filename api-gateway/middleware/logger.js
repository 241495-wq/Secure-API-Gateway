const fs = require("fs");
const path = require("path");
const axios = require("axios");

const logFile = path.join(__dirname, "../logs.txt");

function logger(req, res, next) {
    const logData = {
        time: new Date().toISOString(),
        method: req.method,
        url: req.originalUrl,
        ip: req.ip,
        user: req.user ? req.user.username : "Guest",
        source: "api-gateway",
        message: "Normal request"
    };

    res.on("finish", () => {
        if (req.logMessage) {
            logData.message = req.logMessage;
        }

        logData.status = res.statusCode;

        console.log("LOG:", logData);

        fs.appendFile(logFile, JSON.stringify(logData) + "\n", (err) => {
            if (err) console.error("File log error:", err);
        });

        axios.post("http://localhost:5000/log", logData)
            .catch(err => console.log("Dashboard error:", err.message));
    });

    next();
}

module.exports = { logger };