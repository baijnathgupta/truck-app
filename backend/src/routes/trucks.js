import { Router } from 'express';
import { pool } from '../db/pool.js';
import { auth, role } from '../middleware/auth.js';
const r = Router();

r.get('/', auth, async (req, res) => {
  if (req.user.role === 'ADMIN') {
    const [rows] = await pool.query(
      `SELECT tr.*, u.name AS driver_name FROM trucks tr LEFT JOIN users u ON u.id = tr.driver_id ORDER BY tr.id DESC`
    );
    return res.json({ success: true, trucks: rows });
  }
  let ownerId = req.user.id;
  if (req.user.role === 'DRIVER') {
    const [[u]] = await pool.query('SELECT owner_id FROM users WHERE id = ?', [req.user.id]);
    ownerId = u?.owner_id || 0;
  }
  const [rows] = await pool.query(
    `SELECT tr.*, u.name AS driver_name FROM trucks tr LEFT JOIN users u ON u.id = tr.driver_id WHERE tr.owner_id = ? ORDER BY tr.id DESC`,
    [ownerId]
  );
  res.json({ success: true, trucks: rows });
});

r.post('/', auth, role('OWNER', 'ADMIN'), async (req, res) => {
  const { number, model, capacity } = req.body;
  const [result] = await pool.query(
    'INSERT INTO trucks(owner_id, number, model, capacity) VALUES (?, ?, ?, ?)',
    [req.user.id, number, model, capacity]
  );
  const [rows] = await pool.query('SELECT * FROM trucks WHERE id = ?', [result.insertId]);
  res.status(201).json({ success: true, truck: rows[0] });
});

r.post('/:id/assign-driver', auth, role('OWNER', 'ADMIN'), async (req, res) => {
  const { driverId } = req.body;
  const [[truck]] = await pool.query('SELECT * FROM trucks WHERE id = ? AND owner_id = ?', [req.params.id, req.user.id]);
  if (!truck) return res.status(404).json({ success: false, message: 'Truck not found' });

  if (driverId) {
    const [[driver]] = await pool.query(
      "SELECT id FROM users WHERE id = ? AND role = 'DRIVER' AND owner_id = ?",
      [driverId, req.user.id]
    );
    if (!driver) return res.status(400).json({ success: false, message: 'Driver not found' });
    const [[busy]] = await pool.query('SELECT id, number FROM trucks WHERE driver_id = ? AND id != ?', [driverId, req.params.id]);
    if (busy) return res.status(409).json({ success: false, message: `Driver is already assigned to truck ${busy.number}` });
  }

  await pool.query('UPDATE trucks SET driver_id = ? WHERE id = ?', [driverId || null, req.params.id]);
  const [rows] = await pool.query(
    'SELECT tr.*, u.name AS driver_name FROM trucks tr LEFT JOIN users u ON u.id = tr.driver_id WHERE tr.id = ?',
    [req.params.id]
  );
  res.json({ success: true, truck: rows[0] });
});
export default r;
