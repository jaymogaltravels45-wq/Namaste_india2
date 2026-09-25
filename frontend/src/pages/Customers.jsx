import React, { useEffect, useState } from 'react';
import { adminAPI } from '../services/api';
import toast from 'react-hot-toast';

export default function Customers() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminAPI.customers()
      .then(r => setRows(r.data || []))
      .catch(e => toast.error(e.message || 'Failed to load customers'))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 mb-4">Customers <span className="text-sm font-normal text-gray-400">({rows.length})</span></h2>
      <div className="card !p-0 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-gray-50 text-left text-gray-500">
              <th className="px-4 py-3 font-medium">Name</th>
              <th className="px-4 py-3 font-medium">Phone</th>
              <th className="px-4 py-3 font-medium">Joined</th>
            </tr>
          </thead>
          <tbody>
            {rows.map(c => (
              <tr key={c.id} className="border-t hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">{c.name || '—'}</td>
                <td className="px-4 py-3">{c.phone || '—'}</td>
                <td className="px-4 py-3 text-gray-500">{c.created_at ? new Date(c.created_at).toLocaleDateString('en-IN') : '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {loading && <p className="p-6 text-gray-400 text-sm text-center">Loading…</p>}
        {!loading && rows.length === 0 && <p className="p-6 text-gray-400 text-sm text-center">No customers yet.</p>}
      </div>
    </div>
  );
}
