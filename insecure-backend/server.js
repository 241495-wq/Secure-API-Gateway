const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const axios = require("axios");

const app = express();

app.use(cors());
app.use(bodyParser.json());


// 🔗 SEND LOG TO DASHBOARD
function sendLog(req, message) {
    const log = {
        time: new Date().toISOString(),
        method: req.method,
        url: req.originalUrl,
        ip: req.ip,
        user: "guest",
        message: message,
        source: "insecure-backend"
    };

    axios.post("http://localhost:5000/log", log)
        .catch(() => {});
}


// ❗ Fake database (intentionally insecure)
let users = [
    { id: 1, username: "admin", password: "admin123", role: "admin" },
    { id: 2, username: "user", password: "user123", role: "user" }
];


// 🏠 HOME ROUTE
app.get("/", (req, res) => {
    sendLog(req, "Visited insecure home");
    res.send("INSECURE BACKEND RUNNING");
});


// ❌ LOGIN (NO SECURITY - INTENTIONAL)
app.post("/login", (req, res) => {
    const { username } = req.body;

    sendLog(req, `Login attempt with username: ${username}`);

    // ⚠️ NO PASSWORD CHECK (INTENTIONALLY VULNERABLE)
    let role = username === "admin" ? "admin" : "user";

    res.json({
        message: "Login successful (insecure)",
        user: {
            username,
            role
        }
    });
});


// ❌ GET USERS (NO AUTH)
app.get("/users", (req, res) => {
    sendLog(req, "Fetched all users (no auth)");

    res.json(users);
});


// ❌ DELETE USER (NO AUTHORIZATION)
app.delete("/users/:id", (req, res) => {
    const id = parseInt(req.params.id);

    sendLog(req, `Delete request for user ID: ${id} (no protection)`);

    users = users.filter(u => u.id !== id);

    res.json({
        message: "User deleted (no security check!)"
    });
});


// 🚀 START SERVER
app.listen(3000, () => {
    console.log("🚨 Insecure backend running on http://localhost:3000");
});