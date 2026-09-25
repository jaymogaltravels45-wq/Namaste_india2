// Namaste India Pricing - Source of Truth
const VEHICLES = {
  hatchback: { base: 1500, perKm: 10 },
  sedan:     { base: 1500, perKm: 12 },
  suv:       { base: 2000, perKm: 14 },
  innova:    { base: 3000, perKm: 22 },
};

const LOCAL = {
  hatchback: { "4h/40km": 900,  "8h/80km": 1500, "12h/120km": 2200 },
  sedan:     { "4h/40km": 1200, "8h/80km": 1900, "12h/120km": 2600 },
  suv:       { "4h/40km": 1500, "8h/80km": 2300, "12h/120km": 3100 },
  innova:    { "4h/40km": 2000, "8h/80km": 3000, "12h/120km": 4000 },
};

const calcOutstation = (vehicle, km) => {
  const v = VEHICLES[vehicle];
  if (!v) throw new Error("Unknown vehicle: " + vehicle);
  if (km <= 100) return { totalFare: v.base, breakdown: "Fixed rate (0-100km)", distanceKm: km };
  const extra = (km - 100) * v.perKm;
  return {
    totalFare: v.base + extra,
    breakdown: "Rs." + v.base + " base + " + (km-100) + "km x Rs." + v.perKm + "/km",
    distanceKm: km,
  };
};

const calcLocal = (vehicle, pkg) => {
  const r = LOCAL[vehicle];
  if (!r) throw new Error("Unknown vehicle: " + vehicle);
  const fare = r[pkg];
  if (!fare) throw new Error("Unknown package: " + pkg);
  return { totalFare: fare, breakdown: vehicle + " - " + pkg };
};

module.exports = { calcOutstation, calcLocal, VEHICLES, LOCAL };
