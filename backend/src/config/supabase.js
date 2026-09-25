// Shared Supabase admin client (service role — backend only).
// index.js validates SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY at boot,
// so requiring this module is safe after startup.
const { createClient } = require("@supabase/supabase-js");

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

module.exports = supabaseAdmin;
