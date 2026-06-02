function authorizeRoles(...allowedRoles) {
    return (req, res, next) => {
        if (!req.user) {
            req.logMessage = "Unauthorized: Not authenticated";
            return res.status(401).json({ message: "Not authenticated" });
        }

        if (!allowedRoles.includes(req.user.role)) {
            req.logMessage = "Forbidden: insufficient permissions";
            return res.status(403).json({ 
                message: "Access denied: insufficient permissions"
            });
        }

        next();
    };
}

module.exports = { authorizeRoles };