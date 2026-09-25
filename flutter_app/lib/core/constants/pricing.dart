// Namaste India Pricing -- Single source of truth
const Map<String, int> kBaseFixed = {"hatchback":1500,"sedan":1500,"suv":2000,"innova":3000};
const Map<String, int> kPerKm    = {"hatchback":10,"sedan":12,"suv":14,"innova":22};
const Map<String, Map<String,int>> kLocalRates = {
  "hatchback": {"4h/40km":900, "8h/80km":1500, "12h/120km":2200},
  "sedan":     {"4h/40km":1200,"8h/80km":1900, "12h/120km":2600},
  "suv":       {"4h/40km":1500,"8h/80km":2300, "12h/120km":3100},
  "innova":    {"4h/40km":2000,"8h/80km":3000, "12h/120km":4000},
};

int calcOutstationFare(String vehicle, double km) {
  final base  = kBaseFixed[vehicle] ?? 1500;
  final perKm = kPerKm[vehicle]    ?? 10;
  if (km <= 100) return base;
  return (base + (km - 100) * perKm).round();
}

int calcLocalFare(String vehicle, String package) =>
  kLocalRates[vehicle]?[package] ?? 0;
