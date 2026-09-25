import React, { useEffect, useMemo, useState } from 'react';
import { adminAPI } from '../services/api';
import toast from 'react-hot-toast';
import {
  BarChart, Bar, LineChart, Line, XAxis, YAxis,
  CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts';

// Analytics computed from live bookings — GET /api/admin/bookings + /admin/dashboard.
export default function Analytics() {
  const [bookings, setBookings] = useState([]);
  const [stats, setStats]       = useState(null);

  useEffect(() => {
    adminAPI.bookings().then(r => setBookings(r.data || [])).catch(e => toast.error(e.message || 'Failed to load bookings'));
    adminAPI.dashboard().then(r => setStats(r.data)).catch(() => {});
  }, []);

  const byStatus = useMemo(() => {
    const m = {};
    bookings.forEach(b => { m[b.status] = (m[b.status] || 0) + 1; });
    return Object.entries(m).map(([name, count]) => ({ name: name.replace('_', ' '), count }));
  }, [bookings]);

  const revenueByDay = useMemo(() => {
    const days = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(); d.setDate(d.getDate() - i);
      days.push({ key: d.toISOString().slice(0, 10), label: d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }), revenue: 0, rides: 0 });
    }
    const map = Object.fromEntries(days.map(d => [d.key, d]));
    bookings.forEach(b => {
      const k = new Date(b.createdAt).toISOString().slice(0, 10);
      if (map[k]) {
        map[k].rides += 1;
        if (['cash', 'upi'].includes(b.paymentStatus)) map[k].revenue += (b.finalFare ?? b.estimatedFare ?? 0);
      }
    });
    return days;
  }, [bookings]);

  const totalRevenue = useMemo(
    () => bookings.filter(b => ['cash', 'upi'].includes(b.paymentStatus))
                  .reduce((s, b) => s + (b.finalFare ?? b.estimatedFare ?? 0), 0),
    [bookings]
  );
  const avgRating = useMemo(() => {
    const rated = bookings.filter(b => b.rating);
    return rated.length ? (rated.reduce((s, b) => s + b.rating, 0) / rated.length).toFixed(1) : '—';
  }, [bookings]);

  const cards = [
    { l: 'Total revenue',   v: 'Rs.' + totalRevenue.toLocaleString() },
    { l: 'Total bookings',  v: bookings.length },
    { l: 'Completed rides', v: bookings.filter(b => b.status === 'completed').length },
    { l: 'Avg rating',      v: '★ ' + avgRating },
    { l: 'Pending KYC',     v: stats?.pendingKyc ?? '—' },
  ];

  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 mb-6">Analytics</h2>

      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
        {cards.map(c => (
          <div key={c.l} className="rounded-xl p-5 border border-gray-100 bg-white">
            <p className="text-2xl font-bold text-gray-800">{c.v}</p>
            <p className="text-sm text-gray-500 mt-1">{c.l}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card">
          <h3 className="font-semibold text-gray-700 mb-4">Bookings by status</h3>
          {byStatus.length === 0
            ? <p className="text-sm text-gray-400">No data yet.</p>
            : <ResponsiveContainer width="100%" height={260}>
                <BarChart data={byStatus}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                  <YAxis allowDecimals={false} tick={{ fontSize: 12 }} />
                  <Tooltip />
                  <Bar dataKey="count" fill="#1d4ed8" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>}
        </div>

        <div className="card">
          <h3 className="font-semibold text-gray-700 mb-4">Revenue — last 7 days</h3>
          <ResponsiveContainer width="100%" height={260}>
            <LineChart data={revenueByDay}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="label" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip formatter={(v) => 'Rs.' + Number(v).toLocaleString()} />
              <Line type="monotone" dataKey="revenue" stroke="#16a34a" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
