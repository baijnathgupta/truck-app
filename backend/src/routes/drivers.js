import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool } from '../db/pool.js';
import { auth, role } from '../middleware/auth.js';
const r = Router();

r.get('/', auth, role('OWNER', 'ADMIN'), async (req, res) => {
  const q = req.user.role === 'ADMIN'
    ? "SELECT id, name, phone, created_at FROM users WHERE role = 'DRIVER' ORDER BY id DESC"
    : "SELECT id, name, phone, created_at FROM users WHERE role = 'DRIVER' AND owner_id = ? ORDER BY id DESC";
  const [rows] = await pool.query(q, req.user.role === 'ADMIN' ? [] : [req.user.id]);
  res.json({ success: true, drivers: rows });
});

r.post('/', auth, role('OWNER', 'ADMIN'), async (req, res) => {
  const { name, phone, password } = req.body;
  if (!name || !phone || !password) return res.status(400).json({ success: false, message: 'name, phone and password required' });
  const hash = await bcrypt.hash(password, 10);
  try {
    const [result] = await pool.query(
      'INSERT INTO users(name, phone, password_hash, role, owner_id) VALUES (?, ?, ?, ?, ?)',
      [name, phone, hash, 'DRIVER', req.user.id]
    );
    const [rows] = await pool.query('SELECT id, name, phone, created_at FROM users WHERE id = ?', [result.insertId]);
    res.status(201).json({ success: true, driver: rows[0] });
  } catch (e) {
    res.status(409).json({ success: false, message: 'Phone already registered' });
  }
});
export default r;
