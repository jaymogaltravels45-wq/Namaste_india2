import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:5000/api',
  timeout: 15000,
});

// Attach Supabase access token (stored at admin OTP login) as Bearer.
api.interceptors.request.use(c => {
  const t = localStorage.getItem('ni_admin');
  if (t) c.headers.Authorization = 'Bearer ' + t;
  return c;
});
api.interceptors.response.use(
  r => r.data,
  e => Promise.reject(e.response?.data || e)
);

export const authAPI = {
  sendOtp:   (phone)           => api.post('/auth/send-otp', { phone }),
  verifyOtp: (phone, otp, role)=> api.post('/auth/verify-otp', { phone, otp, role }),
  me:        ()                => api.get('/auth/me'),
};

export const fareAPI = {
  rates:    ()        => api.get('/fare/rates'),
  calcOut:  (v, km)  => api.post('/fare/outstation', { vehicleType: v, distanceKm: km }),
  calcLocal:(v, p)   => api.post('/fare/local', { vehicleType: v, localPackage: p }),
};

export const adminAPI = {
  dashboard:    ()                 => api.get('/admin/dashboard'),
  drivers:      ()                 => api.get('/admin/drivers'),
  kyc:          (id, kycStatus)    => api.patch(`/admin/drivers/${id}/kyc`, { kycStatus }),
  walletAdjust: (id, payload)      => api.patch(`/admin/drivers/${id}/wallet`, payload),
  bookings:     ()                 => api.get('/admin/bookings'),
  customers:    ()                 => api.get('/admin/customers'),
  wallets:      ()                 => api.get('/admin/wallets'),
};

export default api;
