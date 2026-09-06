import { Router } from 'express';
import { pool } from '../db/pool.js';
import { auth, role } from '../middleware/auth.js';
const r = Router();

r.get('/', auth, async (req, res) => {
  if (req.user.role === 'ADMIN') {
    const [rows] = await pool.query('SELECT * FROM trucks ORDER BY id DESC');
    return res.json({ success: true, trucks: rows });
  }
  let ownerId = req.user.id;
  if (req.user.role === 'DRIVER') {
    const [[u]] = await pool.query('SELECT owner_id FROM users WHERE id = ?', [req.user.id]);
    ownerId = u?.owner_id || 0;
  }
  const [rows] = await pool.query('SELECT * FROM trucks WHERE owner_id = ? ORDER BY id DESC', [ownerId]);
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
export default r;
