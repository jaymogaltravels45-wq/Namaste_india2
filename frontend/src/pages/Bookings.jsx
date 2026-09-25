import React, { useEffect, useMemo, useState } from 'react';
import { adminAPI } from '../services/api';
import toast from 'react-hot-toast';

const STATUSES = ['all', 'pending', 'driver_assigned', 'started', 'completed', 'cancelled'];

const statusBadge = (s) => ({
  pending:         'bg-yellow-100 text-yellow-700',
  driver_assigned: 'bg-blue-100 text-blue-700',
  started:         'bg-purple-100 text-purple-700',
  completed:       'bg-green-100 text-green-700',
  cancelled:       'bg-red-100 text-red-700',
}[s] || 'bg-gray-100 text-gray-600');

// All bookings — GET /api/admin/bookings, with status filter.
export default function Bookings() {
  const [rows, setRows]       = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter]   = useState('all');

  useEffect(() => {
    adminAPI.bookings()
      .then(r => setRows(r.data || []))
      .catch(e => toast.error(e.message || 'Failed to load bookings'))
      .finally(() => setLoading(false));
  }, []);

  const filtered = useMemo(
    () => filter === 'all' ? rows : rows.filter(b => b.status === filter),
    [rows, filter]
  );

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold text-gray-800">Bookings <span className="text-sm font-normal text-gray-400">({filtered.length})</span></h2>
        <select className="border rounded-lg px-3 py-2 text-sm" value={filter} onChange={e => setFilter(e.target.value)}>
          {STATUSES.map(s => <option key={s} value={s}>{s === 'all' ? 'All statuses' : s.replace('_', ' ')}</option>)}
        </select>
      </div>

      <div className="card !p-0 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-gray-50 text-left text-gray-500">
              <th className="px-4 py-3 font-medium">Booking #</th>
              <th className="px-4 py-3 font-medium">Customer</th>
              <th className="px-4 py-3 font-medium">Driver</th>
              <th className="px-4 py-3 font-medium">Route</th>
              <th className="px-4 py-3 font-medium">Fare</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Payment</th>
              <th className="px-4 py-3 font-medium">Date</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(b => (
              <tr key={b._id} className="border-t hover:bg-gray-50">
                <td className="px-4 py-3 font-mono text-xs">{b.bookingNumber || b._id.slice(-8)}</td>
                <td className="px-4 py-3">
                  <p className="font-medium">{b.customerId?.name || '—'}</p>
                  <p className="text-xs text-gray-400">{b.customerId?.phone}</p>
                </td>
                <td className="px-4 py-3">
                  <p className="font-medium">{b.driverId?.name || <span className="text-gray-400">unassigned</span>}</p>
                  <p className="text-xs text-gray-400">{b.driverId?.vehicleNumber || ''}</p>
                </td>
                <td className="px-4 py-3 max-w-56">
                  <p className="truncate" title={b.pickup?.address}>{b.pickup?.address}</p>
                  <p className="truncate text-xs text-gray-400" title={b.drop?.address}>→ {b.drop?.address || '—'}</p>
                  <p className="text-xs text-gray-400 capitalize">{b.bookingType} · {b.vehicleType}</p>
                </td>
                <td className="px-4 py-3 font-semibold">Rs.{Number(b.finalFare ?? b.estimatedFare ?? 0).toLocaleString()}</td>
                <td className="px-4 py-3">
                  <span className={'px-2 py-1 rounded-full text-xs font-medium ' + statusBadge(b.status)}>{b.status?.replace('_', ' ')}</span>
                </td>
                <td className="px-4 py-3 text-xs uppercase text-gray-500">{b.paymentStatus}</td>
                <td className="px-4 py-3 text-xs text-gray-500">{new Date(b.createdAt).toLocaleDateString('en-IN')}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {loading && <p className="p-6 text-gray-400 text-sm text-center">Loading…</p>}
        {!loading && filtered.length === 0 && <p className="p-6 text-gray-400 text-sm text-center">No bookings found.</p>}
      </div>
    </div>
  );
}
