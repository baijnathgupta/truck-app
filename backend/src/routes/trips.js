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
  const { truckId, tripNumber, source, destination, goodsType, weight, freight, advance, startDate, expectedDelivery } = req.body;
  let ownerId = req.user.id;

  if (req.user.role === 'DRIVER') {
    const [[u]] = await pool.query('SELECT owner_id FROM users WHERE id = ?', [req.user.id]);
    if (!u?.owner_id) return res.status(400).json({ success: false, message: 'Driver is not linked to an owner' });
    ownerId = u.owner_id;
  }

  if (!truckId) return res.status(400).json({ success: false, message: 'Truck is required' });
  const [[truck]] = await pool.query('SELECT * FROM trucks WHERE id = ? AND owner_id = ?', [truckId, ownerId]);
  if (!truck) return res.status(400).json({ success: false, message: 'Truck not found' });
  if (!truck.driver_id) return res.status(400).json({ success: false, message: 'Assign a driver to this truck before creating a trip' });
  if (req.user.role === 'DRIVER' && truck.driver_id !== req.user.id) {
    return res.status(403).json({ success: false, message: 'You are not the assigned driver for this truck' });
  }
  const assignedDriverId = truck.driver_id;

  const [[activeTrip]] = await pool.query(
    "SELECT id FROM trips WHERE truck_id = ? AND status != 'COMPLETED' LIMIT 1",
    [truckId]
  );
  if (activeTrip) return res.status(409).json({ success: false, message: 'This truck already has an active trip' });

  const [result] = await pool.query(`
    INSERT INTO trips(owner_id, driver_id, truck_id, trip_number, source, destination, goods_type, weight, freight, advance, start_date, expected_delivery)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [ownerId, assignedDriverId, truckId, tripNumber, source, destination, goodsType, weight, freight || 0, advance || 0, startDate, expectedDelivery]
  );
  const [rows] = await pool.query('SELECT * FROM trips WHERE id = ?', [result.insertId]);
  res.status(201).json({ success: true, trip: rows[0] });
});

r.post('/:id/complete', auth, role('OWNER', 'ADMIN', 'DRIVER'), async (req, res) => {
  let sql = "UPDATE trips SET status = 'COMPLETED' WHERE id = ?";
  const params = [req.params.id];
  if (req.user.role === 'OWNER') { sql += ' AND owner_id = ?'; params.push(req.user.id); }
  else if (req.user.role === 'DRIVER') { sql += ' AND driver_id = ?'; params.push(req.user.id); }
  const [result] = await pool.query(sql, params);
  const [rows] = await pool.query('SELECT * FROM trips WHERE id = ?', [req.params.id]);
  res.json({ success: result.affectedRows > 0, trip: rows[0] || null });
});
export default r;
