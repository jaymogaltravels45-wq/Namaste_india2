// Shared display-info helper: identity fields are Supabase UUID strings,
// so customer/driver names are resolved by string lookups (no Mongoose populate).
const supabaseAdmin = require("../config/supabase");
const Driver = require("../models/Driver");

/**
 * For each booking object (plain/lean), attach:
 *  - b.customer = { name, phone }   (from Supabase profiles)
 *  - b.driverId = { name, phone, vehicleNumber, vehicleModel, rating }
 *    (from Mongo Driver, replacing the raw UUID string — matches Flutter's
 *    expectation that driverId is a populated map when a driver is assigned)
 * Failures are display-only and never reject.
 */
async function attachParties(list) {
  for (const b of list) {
    try {
      if (b.customerId) {
        const { data: p } = await supabaseAdmin
          .from("profiles").select("name,phone").eq("id", String(b.customerId)).maybeSingle();
        if (p) b.customer = { name: p.name || "Customer", phone: p.phone || "" };
      }
    } catch (_) { /* display-only */ }
    try {
      if (b.driverId && typeof b.driverId === "string") {
        const d = await Driver.findOne({ userId: b.driverId })
          .select("name phone vehicleNumber vehicleModel rating").lean();
        if (d) b.driverId = {
          name: d.name, phone: d.phone,
          vehicleNumber: d.vehicleNumber, vehicleModel: d.vehicleModel, rating: d.rating,
        };
      }
    } catch (_) { /* display-only */ }
  }
  return list;
}

module.exports = { attachParties };
