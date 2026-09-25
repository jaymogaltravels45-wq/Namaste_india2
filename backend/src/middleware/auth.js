const supabaseAdmin = require("../config/supabase");

/**
 * authMiddleware — validates Supabase JWT from Authorization: Bearer <token>
 * Attaches req.user = { id, phone, role, email }
 */
const authMiddleware = async (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token)
    return res.status(401).json({ success: false, message: "No token provided" });

  try {
    // Supabase verifies the JWT and returns the user
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);
    if (error || !user)
      return res.status(401).json({ success: false, message: "Invalid or expired token" });

    req.user = {
      id: user.id,
      email: user.email,
      phone: user.phone || user.user_metadata?.phone,
      role: user.user_metadata?.role || "customer",
    };
    next();
  } catch (e) {
    return res.status(401).json({ success: false, message: "Token verification failed" });
  }
};

/**
 * adminOnly — must be used after authMiddleware
 */
const adminOnly = (req, res, next) =>
  req.user?.role === "admin"
    ? next()
    : res.status(403).json({ success: false, message: "Admin access only" });

module.exports = { authMiddleware, adminOnly };
