import React, { useEffect, useState } from 'react';
import { adminAPI } from '../services/api';
import toast from 'react-hot-toast';

const typeBadge = (t) => ({
  credit:  'bg-green-100 text-green-700',
  debit:   'bg-red-100 text-red-700',
  penalty: 'bg-orange-100 text-orange-700',
  refund:  'bg-blue-100 text-blue-700',
}[t] || 'bg-gray-100 text-gray-600');

// All driver wallet transactions — GET /api/admin/wallets
export default function Wallets() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminAPI.wallets()
      .then(r => setRows(r.data || []))
      .catch(e => toast.error(e.message || 'Failed to load wallet transactions'))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 mb-4">Wallets <span className="text-sm font-normal text-gray-400">({rows.length} transactions)</span></h2>
      <div className="card !p-0 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-gray-50 text-left text-gray-500">
              <th className="px-4 py-3 font-medium">Driver</th>
              <th className="px-4 py-3 font-medium">Type</th>
              <th className="px-4 py-3 font-medium">Amount</th>
              <th className="px-4 py-3 font-medium">Balance after</th>
              <th className="px-4 py-3 font-medium">Description</th>
              <th className="px-4 py-3 font-medium">Date</th>
            </tr>
          </thead>
          <tbody>
            {rows.map(t => (
              <tr key={t._id} className="border-t hover:bg-gray-50">
                <td className="px-4 py-3">
                  <p className="font-medium">{t.driverId?.name || '—'}</p>
                  <p className="text-xs text-gray-400">{t.driverId?.phone}</p>
                </td>
                <td className="px-4 py-3">
                  <span className={'px-2 py-1 rounded-full text-xs font-medium ' + typeBadge(t.type)}>{t.type}</span>
                </td>
                <td className={'px-4 py-3 font-semibold ' + (t.amount < 0 ? 'text-red-600' : 'text-green-600')}>
                  {t.amount < 0 ? '−' : '+'}Rs.{Math.abs(t.amount).toLocaleString()}
                </td>
                <td className="px-4 py-3">Rs.{Number(t.balance).toLocaleString()}</td>
                <td className="px-4 py-3 text-gray-500 max-w-48 truncate">{t.description || '—'}</td>
                <td className="px-4 py-3 text-gray-500 text-xs">{new Date(t.createdAt).toLocaleString('en-IN')}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {loading && <p className="p-6 text-gray-400 text-sm text-center">Loading…</p>}
        {!loading && rows.length === 0 && <p className="p-6 text-gray-400 text-sm text-center">No wallet transactions yet.</p>}
      </div>
    </div>
  );
}
