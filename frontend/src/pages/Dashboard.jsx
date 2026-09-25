import React, { useEffect, useState } from 'react';
import { adminAPI, fareAPI } from '../services/api';
import toast from 'react-hot-toast';

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [rates, setRates] = useState(null); // { out: {vehicle:{base,perKm}}, local: {vehicle:{pkg:fare}} }
  const [vehicle, setVehicle] = useState('sedan');
  const [km, setKm]           = useState(150);
  const [type, setType]       = useState('outstation');
  const [pkg, setPkg]         = useState('4h/40km');

  useEffect(() => {
    adminAPI.dashboard()
      .then(r => setStats(r.data))
      .catch(e => toast.error(e.message || 'Failed to load dashboard'));
    fareAPI.rates()
      .then(r => setRates({ out: r.vehicleRates, local: r.localRates }))
      .catch(() => toast.error('Failed to load fare rates'));
  }, []);

  const fare = () => {
    if (!rates) return 0;
    if (type === 'local') return rates.local?.[vehicle]?.[pkg] || 0;
    const v = rates.out?.[vehicle];
    if (!v) return 0;
    const d = Number(km) || 0;
    return d <= 100 ? v.base : v.base + (d - 100) * v.perKm;
  };

  const breakdown = () => {
    if (!rates) return '';
    if (type === 'local') return vehicle + ' — ' + pkg;
    const v = rates.out?.[vehicle];
    if (!v) return '';
    const d = Number(km) || 0;
    return d <= 100 ? 'Fixed rate (0–100 km)' : `Rs.${v.base} + ${d - 100} km × Rs.${v.perKm}/km`;
  };

  const cards = stats ? [
    { l: 'Bookings',     v: stats.bookings ?? 0,                        col: 'text-blue-600',   bg: 'bg-blue-50' },
    { l: 'Drivers',      v: stats.drivers ?? 0,                         col: 'text-green-600',  bg: 'bg-green-50' },
    { l: 'Customers',    v: stats.customers ?? 0,                       col: 'text-purple-600', bg: 'bg-purple-50' },
    { l: 'Revenue',      v: 'Rs.' + Number(stats.revenue ?? 0).toLocaleString(), col: 'text-orange-600', bg: 'bg-orange-50' },
    { l: 'KYC Pending',  v: stats.pendingKyc ?? 0,                      col: 'text-red-600',    bg: 'bg-red-50' },
  ] : [];

  const vehicles = rates ? Object.keys(rates.out) : [];

  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 mb-6">Dashboard</h2>

      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
        {cards.map(s => (
          <div key={s.l} className={'rounded-xl p-5 border border-gray-100 ' + s.bg}>
            <p className={'text-2xl font-bold ' + s.col}>{s.v}</p>
            <p className="text-sm text-gray-500 mt-1">{s.l}</p>
          </div>
        ))}
        {cards.length === 0 && <p className="text-sm text-gray-400 col-span-full">Loading stats…</p>}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card">
          <h3 className="font-semibold text-gray-700 mb-4">Fare Calculator</h3>
          <div className="space-y-3">
            <div className="flex gap-2">
              <select className="flex-1 border rounded-lg px-3 py-2 text-sm" value={type} onChange={e => setType(e.target.value)}>
                <option value="outstation">Outstation</option>
                <option value="local">Local</option>
              </select>
              <select className="flex-1 border rounded-lg px-3 py-2 text-sm" value={vehicle} onChange={e => setVehicle(e.target.value)}>
                {vehicles.map(k => <option key={k} value={k} className="capitalize">{k}</option>)}
              </select>
            </div>
            {type === 'outstation'
              ? <input type="number" min="0" className="w-full border rounded-lg px-3 py-2 text-sm" value={km} onChange={e => setKm(e.target.value)} placeholder="Distance KM" />
              : <select className="w-full border rounded-lg px-3 py-2 text-sm" value={pkg} onChange={e => setPkg(e.target.value)}>
                  <option value="4h/40km">4h / 40km</option>
                  <option value="8h/80km">8h / 80km</option>
                  <option value="12h/120km">12h / 120km</option>
                </select>}
            <div className="bg-blue-50 rounded-xl p-4 text-center">
              <p className="text-sm text-gray-500">Estimated Fare</p>
              <p className="text-3xl font-bold text-blue-700">Rs.{fare().toLocaleString()}</p>
              <p className="text-xs text-gray-400 mt-1">{breakdown()}</p>
            </div>
          </div>
        </div>

        <div className="card">
          <h3 className="font-semibold text-gray-700 mb-4">All Rates <span className="text-xs font-normal text-gray-400">(live from API)</span></h3>
          {!rates && <p className="text-sm text-gray-400">Loading rates…</p>}
          {rates && <>
            <p className="text-xs text-gray-500 mb-2 font-semibold">OUTSTATION</p>
            <table className="w-full text-sm mb-4">
              <thead><tr className="border-b text-gray-400 text-left"><th className="pb-1">Vehicle</th><th>0–100 km</th><th>/km above</th></tr></thead>
              <tbody>{Object.entries(rates.out).map(([k, r]) => (
                <tr key={k} className="border-b last:border-0">
                  <td className="py-1.5 capitalize font-medium">{k}</td><td>Rs.{r.base}</td><td>Rs.{r.perKm}</td>
                </tr>))}</tbody>
            </table>
            <p className="text-xs text-gray-500 mb-2 font-semibold">LOCAL PACKAGES</p>
            <table className="w-full text-sm">
              <thead><tr className="border-b text-gray-400 text-left"><th className="pb-1">Vehicle</th><th>4h</th><th>8h</th><th>12h</th></tr></thead>
              <tbody>{Object.entries(rates.local).map(([k, p]) => (
                <tr key={k} className="border-b last:border-0">
                  <td className="py-1.5 capitalize font-medium">{k}</td>
                  <td>Rs.{p['4h/40km']}</td><td>Rs.{p['8h/80km']}</td><td>Rs.{p['12h/120km']}</td>
                </tr>))}</tbody>
            </table>
          </>}
        </div>
      </div>
    </div>
  );
}
