import React, { useEffect, useState } from 'react';
import { adminAPI } from '../services/api';
import toast from 'react-hot-toast';

const kycBadge = (s) => ({
  verified: 'bg-green-100 text-green-700',
  rejected: 'bg-red-100 text-red-700',
  pending:  'bg-yellow-100 text-yellow-700',
}[s] || 'bg-gray-100 text-gray-600');

export default function Drivers() {
  const [rows, setRows]       = useState([]);
  const [loading, setLoading] = useState(true);
  const [adjustId, setAdjustId] = useState(null);
  const [form, setForm] = useState({ amount: '', type: 'credit', description: '' });

  const load = () => {
    setLoading(true);
    adminAPI.drivers()
      .then(r => setRows(r.data || []))
      .catch(e => toast.error(e.message || 'Failed to load drivers'))
      .finally(() => setLoading(false));
  };
  useEffect(load, []);

  const setKyc = async (id, kycStatus) => {
    try {
      await adminAPI.kyc(id, kycStatus);
      toast.success('KYC ' + kycStatus);
      load();
    } catch (e) { toast.error(e.message || 'Failed to update KYC'); }
  };

  const adjust = async (e) => {
    e.preventDefault();
    const amount = parseFloat(form.amount);
    if (!Number.isFinite(amount) || amount === 0) return toast.error('Enter a valid non-zero amount');
    try {
      await adminAPI.walletAdjust(adjustId, {
        amount, type: form.type, description: form.description || 'Admin adjustment',
      });
      toast.success('Wallet updated');
      setAdjustId(null);
      setForm({ amount: '', type: 'credit', description: '' });
      load();
    } catch (err) { toast.error(err.message || 'Failed to adjust wallet'); }
  };

  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 mb-4">Drivers <span className="text-sm font-normal text-gray-400">({rows.length})</span></h2>

      <div className="card !p-0 overflow-hidden mb-6">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-gray-50 text-left text-gray-500">
              <th className="px-4 py-3 font-medium">Driver</th>
              <th className="px-4 py-3 font-medium">Vehicle</th>
              <th className="px-4 py-3 font-medium">KYC</th>
              <th className="px-4 py-3 font-medium">Wallet</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map(d => (
              <tr key={d._id} className="border-t hover:bg-gray-50">
                <td className="px-4 py-3">
                  <p className="font-medium">{d.name || '—'}</p>
                  <p className="text-xs text-gray-400">{d.phone}</p>
                </td>
                <td className="px-4 py-3">
                  <p className="capitalize">{d.vehicleType}</p>
                  <p className="text-xs text-gray-400">{d.vehicleNumber}</p>
                </td>
                <td className="px-4 py-3">
                  <span className={'px-2 py-1 rounded-full text-xs font-medium ' + kycBadge(d.kycStatus)}>{d.kycStatus}</span>
                  {d.kycStatus === 'pending' && (
                    <div className="flex gap-1 mt-1.5">
                      <button onClick={() => setKyc(d._id, 'verified')} className="text-xs bg-green-600 text-white px-2 py-1 rounded">Verify</button>
                      <button onClick={() => setKyc(d._id, 'rejected')} className="text-xs bg-red-600 text-white px-2 py-1 rounded">Reject</button>
                    </div>
                  )}
                </td>
                <td className={'px-4 py-3 font-semibold ' + (d.walletBalance < 0 ? 'text-red-600' : 'text-gray-800')}>
                  Rs.{Number(d.walletBalance || 0).toLocaleString()}
                  {!d.canAcceptBookings && <p className="text-xs font-normal text-red-500">blocked</p>}
                </td>
                <td className="px-4 py-3 text-xs">
                  <span className={d.isOnline ? 'text-green-600 font-medium' : 'text-gray-400'}>{d.isOnline ? '● Online' : '○ Offline'}</span>
                  <p className="text-gray-400">★ {d.rating || 0} · {d.totalTrips || 0} trips</p>
                </td>
                <td className="px-4 py-3">
                  <button onClick={() => setAdjustId(adjustId === d._id ? null : d._id)}
                    className="text-xs bg-blue-600 text-white px-2.5 py-1.5 rounded-lg">Adjust wallet</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {loading && <p className="p-6 text-gray-400 text-sm text-center">Loading…</p>}
        {!loading && rows.length === 0 && <p className="p-6 text-gray-400 text-sm text-center">No drivers yet.</p>}
      </div>

      {adjustId && (
        <form onSubmit={adjust} className="card">
          <h3 className="font-semibold text-gray-700 mb-3">Wallet adjustment</h3>
          <div className="flex flex-wrap gap-2">
            <input type="number" step="any" placeholder="Amount (negative for debit)"
              className="border rounded-lg px-3 py-2 text-sm w-56"
              value={form.amount} onChange={e => setForm({ ...form, amount: e.target.value })} />
            <select className="border rounded-lg px-3 py-2 text-sm" value={form.type}
              onChange={e => setForm({ ...form, type: e.target.value })}>
              <option value="credit">Credit</option>
              <option value="debit">Debit</option>
              <option value="penalty">Penalty</option>
              <option value="refund">Refund</option>
            </select>
            <input placeholder="Description (optional)" className="border rounded-lg px-3 py-2 text-sm flex-1 min-w-40"
              value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
            <button className="bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium">Apply</button>
            <button type="button" onClick={() => setAdjustId(null)} className="text-sm text-gray-500 px-3">Cancel</button>
          </div>
        </form>
      )}
    </div>
  );
}
