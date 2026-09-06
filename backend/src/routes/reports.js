import { Router } from 'express';
import { pool } from '../db/pool.js';
import { auth, role } from '../middleware/auth.js';
const r = Router();

r.get('/monthly', auth, role('OWNER', 'ADMIN'), async (req, res) => {
  const month = req.query.month || new Date().toISOString().slice(0, 7);
  const owner = req.user.role === 'ADMIN' ? null : req.user.id;

  let tripSql = `SELECT COUNT(*) AS trips, COALESCE(SUM(freight), 0) AS revenue
                 FROM trips WHERE DATE_FORMAT(start_date, '%Y-%m') = ?`;
  let expSql = `SELECT COALESCE(SUM(e.amount), 0) AS expenses
                FROM expenses e JOIN trips t ON t.id = e.trip_id
                WHERE e.status = 'APPROVED' AND DATE_FORMAT(e.created_at, '%Y-%m') = ?`;
  const tripParams = [month];
  const expParams = [month];
  if (owner) {
    tripSql += ' AND owner_id = ?'; tripParams.push(owner);
    expSql += ' AND t.owner_id = ?'; expParams.push(owner);
  }

  const [[trip]] = await pool.query(tripSql, tripParams);
  const [[exp]] = await pool.query(expSql, expParams);
  const revenue = Number(trip.revenue || 0);
  const expenses = Number(exp.expenses || 0);
  res.json({ success: true, month, trips: Number(trip.trips || 0), revenue, expenses, profit: revenue - expenses });
});
export default r;
