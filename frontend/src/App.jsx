import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import Layout    from './components/Layout';
import Dashboard from './pages/Dashboard';
import Bookings  from './pages/Bookings';
import Drivers   from './pages/Drivers';
import Customers from './pages/Customers';
import Fares     from './pages/Fares';
import Wallets   from './pages/Wallets';
import Analytics from './pages/Analytics';
import Login     from './pages/Login';
const Priv = ({children}) => localStorage.getItem('ni_admin') ? children : <Navigate to="/login"/>;
export default function App() {
  return (<Routes>
    <Route path="/login" element={<Login/>}/>
    <Route path="/" element={<Priv><Layout/></Priv>}>
      <Route index element={<Dashboard/>}/>
      <Route path="bookings"  element={<Bookings/>}/>
      <Route path="drivers"   element={<Drivers/>}/>
      <Route path="customers" element={<Customers/>}/>
      <Route path="fares"     element={<Fares/>}/>
      <Route path="wallets"   element={<Wallets/>}/>
      <Route path="analytics" element={<Analytics/>}/>
    </Route>
  </Routes>);
}
