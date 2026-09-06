import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db/pool.js';
const router = Router();

router.post('/register', async (req, res) => {
  const { name, phone, password, role = 'OWNER' } = req.body;
  if (!name || !phone || !password) return res.status(400).json({ success: false, message: 'name, phone and password required' });
  const hash = await bcrypt.hash(password, 10);
  try {
    const [result] = await pool.query(
      'INSERT INTO users(name, phone, password_hash, role) VALUES (?, ?, ?, ?)',
      [name, phone, hash, role]
    );
    const [rows] = await pool.query('SELECT id, name, phone, role FROM users WHERE id = ?', [result.insertId]);
    res.json({ success: true, user: rows[0] });
  } catch (e) {
    res.status(409).json({ success: false, message: 'Phone already registered' });
  }
});

router.post('/login', async (req, res) => {
  const { phone, password } = req.body;
  const [rows] = await pool.query('SELECT * FROM users WHERE phone = ? LIMIT 1', [phone]);
  if (!rows.length || !(await bcrypt.compare(password, rows[0].password_hash)))
    return res.status(401).json({ success: false, message: 'Invalid login' });
  const u = rows[0];
  const token = jwt.sign({ id: u.id, role: u.role, name: u.name }, process.env.JWT_SECRET, { expiresIn: '30d' });
  res.json({ success: true, token, user: { id: u.id, name: u.name, phone: u.phone, role: u.role } });
});
export default router;
