const { detectMaliciousInput } = require("./middleware/validator");
const { logger } = require("./middleware/logger");
const { authorizeRoles } = require("./middleware/role");
const rateLimit = require("express-rate-limit");
const jwt = require("jsonwebtoken");
const { SECRET_KEY } = require("./middleware/auth");
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const axios = require("axios");

const app = express();

app.use(cors());
app.use(bodyParser.json());


// Backend URL (your insecure backend)
const BACKEND_URL = "http://localhost:3000";

const limiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 5, // max 5 requests per minute
    message: {
        message: "Too many requests, please try again later"
    }
});

app.use(limiter);
app.post("/api/login", logger, detectMaliciousInput, (req, res) => {
    const { username } = req.body;

    // fake login (we are not using DB here yet)
    const user = {
        id: 1,
        username: username,
        role: username === "admin" ? "admin" : "user"
    };

    const token = jwt.sign(user, SECRET_KEY, { expiresIn: "1h" });

    res.json({
        message: "Login successful",
        token: token
    });
});

app.delete("/api/users/:id", authorizeRoles("admin"), async (req, res) => {
    res.json({
        message: "User deleted (admin only action allowed)"
    });
});


// 🔁 REQUEST ROUTING (Gateway Core)
const { authenticateToken } = require("./middleware/auth");

app.use("/api", logger, detectMaliciousInput, authenticateToken, async (req, res) => {
    try {
        const response = await axios({
            method: req.method,
            url: BACKEND_URL + req.originalUrl.replace("/api", ""),
            data: req.body
        });

        res.json(response.data);
    } catch (err) {
        res.status(500).json({ error: "Gateway error", details: err.message });
    }
});

app.listen(4000, () => {
    console.log("API Gateway running on port 4000");
});

