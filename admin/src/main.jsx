import React,{useEffect,useState} from 'react';
import {createRoot} from 'react-dom/client';
import './style.css';
const API='http://localhost:4000/api';
function App(){
 const [data,setData]=useState(null),[month,setMonth]=useState(new Date().toISOString().slice(0,7));
 useEffect(()=>{fetch(`${API}/reports/monthly?month=${month}`,{headers:{Authorization:'Bearer '+(localStorage.token||'') }}).then(r=>{if(!r.ok)throw new Error('request failed');return r.json();}).then(setData).catch(()=>setData(null));},[month]);
 return <div className="app"><aside><h2>TruckTrip</h2><p>Dashboard</p><p>Trucks</p><p>Drivers</p><p>Trips</p><p>Expenses</p><p>Reports</p></aside><main><h1>Fleet Dashboard</h1><label>Month <input type="month" value={month} onChange={e=>setMonth(e.target.value)}/></label><div className="grid"><Card t="Trips" v={data?.trips??'--'}/><Card t="Revenue" v={data?.revenue!=null?'₹'+data.revenue.toLocaleString():'--'}/><Card t="Expenses" v={data?.expenses!=null?'₹'+data.expenses.toLocaleString():'--'}/><Card t="Profit" v={data?.profit!=null?'₹'+data.profit.toLocaleString():'--'}/></div><section><h2>Monthly Report</h2><p>Revenue minus approved expenses gives the current trip profit.</p></section></main></div>}
function Card({t,v}){return <div className="card"><span>{t}</span><strong>{v}</strong></div>}
createRoot(document.getElementById('root')).render(<App/>);
