import React, { useEffect, useState } from 'react';
import { fareAPI } from '../services/api';
import toast from 'react-hot-toast';

// Fare tables — live from GET /api/fare/rates (backend is the source of truth).
export default function Fares() {
  const [rates, setRates] = useState(null);

  useEffect(() => {
    fareAPI.rates()
      .then(r => setRates({ out: r.vehicleRates, local: r.localRates }))
      .catch(() => toast.error('Failed to load fare rates'));
  }, []);

  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 mb-4">Fare Rates</h2>
      {!rates && <p className="text-sm text-gray-400">Loading rates…</p>}
      {rates && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="card">
            <h3 className="font-semibold text-gray-700 mb-4">Outstation <span className="text-xs font-normal text-gray-400">— fixed up to 100 km, then per-km</span></h3>
            <table className="w-full text-sm">
              <thead><tr className="border-b text-gray-400 text-left"><th className="pb-2">Vehicle</th><th>0–100 km (fixed)</th><th>Per km above 100</th></tr></thead>
              <tbody>
                {Object.entries(rates.out).map(([v, r]) => (
                  <tr key={v} className="border-b last:border-0">
                    <td className="py-2.5 capitalize font-medium">{v}</td>
                    <td>Rs.{r.base.toLocaleString()}</td>
                    <td>Rs.{r.perKm}/km</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="card">
            <h3 className="font-semibold text-gray-700 mb-4">Local Packages</h3>
            <table className="w-full text-sm">
              <thead><tr className="border-b text-gray-400 text-left"><th className="pb-2">Vehicle</th><th>4h / 40km</th><th>8h / 80km</th><th>12h / 120km</th></tr></thead>
              <tbody>
                {Object.entries(rates.local).map(([v, p]) => (
                  <tr key={v} className="border-b last:border-0">
                    <td className="py-2.5 capitalize font-medium">{v}</td>
                    <td>Rs.{p['4h/40km'].toLocaleString()}</td>
                    <td>Rs.{p['8h/80km'].toLocaleString()}</td>
                    <td>Rs.{p['12h/120km'].toLocaleString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
