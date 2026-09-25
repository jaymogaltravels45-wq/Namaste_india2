import React, { useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
const nav = [
  { to:'/',           label:'Dashboard' },
  { to:'/bookings',   label:'Bookings'  },
  { to:'/drivers',    label:'Drivers'   },
  { to:'/customers',  label:'Customers' },
  { to:'/fares',      label:'Fares'     },
  { to:'/wallets',    label:'Wallets'   },
  { to:'/analytics',  label:'Analytics' },
];
export default function Layout() {
  const [open,setOpen] = useState(true);
  const navigate = useNavigate();
  const logout = () => { localStorage.removeItem('ni_admin'); navigate('/login'); };
  return (
    <div className="flex h-screen">
      <aside className={(open?'w-60':'w-14')+' bg-blue-900 text-white flex flex-col transition-all duration-200'}>
        <div className="flex items-center p-4 border-b border-blue-800">
          <button onClick={()=>setOpen(!open)} className="text-white font-bold text-lg">{open?'<':'>'}</button>
          {open && <span className="ml-3 font-bold text-sm">Namaste India</span>}
        </div>
        <nav className="flex-1 p-2 space-y-1">
          {nav.map(n => (
            <NavLink key={n.to} to={n.to} end={n.to==='/'}
              className={({isActive}) => 'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm '+(isActive?'bg-blue-700 text-white':'text-blue-200 hover:bg-blue-800')}>
              {open ? n.label : n.label[0]}
            </NavLink>
          ))}
        </nav>
        <button onClick={logout} className="p-4 text-blue-300 hover:text-white text-sm border-t border-blue-800">{open?'Logout':'X'}</button>
      </aside>
      <div className="flex-1 flex flex-col overflow-hidden">
        <header className="bg-white border-b px-6 py-3 flex items-center justify-between shadow-sm">
          <h1 className="text-lg font-semibold text-gray-800">Admin Panel</h1>
          <span className="text-sm text-gray-400">Namaste India</span>
        </header>
        <main className="flex-1 overflow-auto p-6"><Outlet/></main>
      </div>
    </div>
  );
}
