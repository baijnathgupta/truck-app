import { Router } from 'express';
import { pool } from '../db/pool.js';
import { auth, role } from '../middleware/auth.js';
const r = Router();

r.get('/', auth, async (req, res) => {
  let q = `SELECT t.*, u.name AS driver_name, tr.number AS truck_number
           FROM trips t
           LEFT JOIN users u ON u.id = t.driver_id
           LEFT JOIN trucks tr ON tr.id = t.truck_id
           WHERE t.owner_id = ? ORDER BY t.id DESC`;
  const params = [req.user.id];
  if (req.user.role === 'DRIVER') {
    q = `SELECT t.*, u.name AS driver_name, tr.number AS truck_number
         FROM trips t
         LEFT JOIN users u ON u.id = t.driver_id
         LEFT JOIN trucks tr ON tr.id = t.truck_id
         WHERE t.driver_id = ? ORDER BY t.id DESC`;
  }
  const [rows] = await pool.query(q, params);
  res.json({ success: true, trips: rows });
});

r.post('/', auth, role('OWNER', 'ADMIN', 'DRIVER'), async (req, res) => {
  const { driverId, truckId, tripNumber, source, destination, goodsType, weight, freight, advance, startDate, expectedDelivery } = req.body;
  let ownerId = req.user.id;
  let assignedDriverId = driverId ?? null;
  if (req.user.role === 'DRIVER') {
    const [[u]] = await pool.query('SELECT owner_id FROM users WHERE id = ?', [req.user.id]);
    if (!u?.owner_id) return res.status(400).json({ success: false, message: 'Driver is not linked to an owner' });
    ownerId = u.owner_id;
    assignedDriverId = req.user.id;
  }
  const [result] = await pool.query(`
    INSERT INTO trips(owner_id, driver_id, truck_id, trip_number, source, destination, goods_type, weight, freight, advance, start_date, expected_delivery)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [ownerId, assignedDriverId, truckId, tripNumber, source, destination, goodsType, weight, freight || 0, advance || 0, startDate, expectedDelivery]
  );
  const [rows] = await pool.query('SELECT * FROM trips WHERE id = ?', [result.insertId]);
  res.status(201).json({ success: true, trip: rows[0] });
});
export default r;
