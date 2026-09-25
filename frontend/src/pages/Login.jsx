import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { authAPI } from '../services/api';
import toast from 'react-hot-toast';

// Admin login: phone + OTP via backend (role=admin). The Supabase access
// token is stored and attached as Bearer on every admin API call.
export default function Login() {
  const [step, setStep]     = useState(1); // 1 = phone, 2 = otp
  const [phone, setPhone]   = useState('');
  const [otp, setOtp]       = useState('');
  const [loading, setLoading] = useState(false);
  const nav = useNavigate();

  const sendOtp = async (e) => {
    e.preventDefault();
    if (!/^[+\d][\d\s-]{6,16}$/.test(phone.trim()))
      return toast.error('Enter a valid phone number');
    setLoading(true);
    try {
      const r = await authAPI.sendOtp(phone.trim());
      toast.success(r.mock ? `Mock OTP sent — use ${r.message.match(/\d{6}/)?.[0] || '123456'}` : 'OTP sent to your phone');
      setStep(2);
    } catch (err) {
      toast.error(err.message || 'Failed to send OTP');
    } finally { setLoading(false); }
  };

  const verify = async (e) => {
    e.preventDefault();
    if (!/^\d{4,8}$/.test(otp.trim())) return toast.error('Enter the OTP digits');
    setLoading(true);
    try {
      const r = await authAPI.verifyOtp(phone.trim(), otp.trim(), 'admin');
      if (r.user?.role !== 'admin') {
        toast.error('This panel is for admins only');
        return;
      }
      localStorage.setItem('ni_admin', r.session.access_token);
      toast.success('Welcome back, admin');
      nav('/');
    } catch (err) {
      toast.error(err.message || 'Invalid or expired OTP');
    } finally { setLoading(false); }
  };

  return (
    <div className="min-h-screen bg-blue-900 flex items-center justify-center px-4">
      <div className="bg-white rounded-2xl shadow-xl p-8 w-full max-w-sm">
        <h1 className="text-2xl font-bold text-blue-900 text-center mb-1">Namaste India</h1>
        <p className="text-gray-500 text-sm text-center mb-6">Admin Panel — OTP Login</p>

        {step === 1 ? (
          <form onSubmit={sendOtp} className="space-y-4">
            <div>
              <label className="text-xs font-medium text-gray-600">Admin phone number</label>
              <input
                className="w-full border rounded-lg px-3 py-2.5 text-sm mt-1"
                placeholder="+91 98765 43210"
                value={phone} onChange={e => setPhone(e.target.value)}
                inputMode="tel" autoFocus />
            </div>
            <button disabled={loading}
              className="w-full bg-blue-700 hover:bg-blue-800 disabled:opacity-50 text-white py-2.5 rounded-lg font-medium">
              {loading ? 'Sending…' : 'Send OTP'}
            </button>
          </form>
        ) : (
          <form onSubmit={verify} className="space-y-4">
            <p className="text-xs text-gray-500">OTP sent to <span className="font-semibold text-gray-700">{phone}</span>
              <button type="button" onClick={() => setStep(1)} className="ml-2 text-blue-600 underline">change</button>
            </p>
            <div>
              <label className="text-xs font-medium text-gray-600">Enter OTP</label>
              <input
                className="w-full border rounded-lg px-3 py-2.5 text-sm mt-1 tracking-[0.5em] text-center font-bold"
                placeholder="••••••" maxLength={8}
                value={otp} onChange={e => setOtp(e.target.value.replace(/\D/g, ''))}
                inputMode="numeric" autoFocus />
            </div>
            <button disabled={loading}
              className="w-full bg-blue-700 hover:bg-blue-800 disabled:opacity-50 text-white py-2.5 rounded-lg font-medium">
              {loading ? 'Verifying…' : 'Verify & Login'}
            </button>
          </form>
        )}
        <p className="text-xs text-gray-400 text-center mt-4">Only numbers registered as admin can sign in.</p>
      </div>
    </div>
  );
}
