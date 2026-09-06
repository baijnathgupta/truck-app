import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import { pool } from '../db/pool.js';
import { auth, role } from '../middleware/auth.js';
const r = Router();
const upload = multer({
  storage: multer.diskStorage({
    destination: 'uploads/receipts',
    filename: (req, file, cb) => cb(null, Date.now() + '-' + Math.round(Math.random() * 1e9) + path.extname(file.originalname))
  }),
  limits: { fileSize: 10 * 1024 * 1024 }
});

r.get('/', auth, async (req, res) => {
  let sql = `SELECT e.*, c.name AS category, u.name AS created_by_name, t.trip_number, t.truck_id
             FROM expenses e
             LEFT JOIN expense_categories c ON c.id = e.category_id
             JOIN users u ON u.id = e.created_by
             LEFT JOIN trips t ON t.id = e.trip_id `;
  let params = [];
  if (req.user.role === 'DRIVER') { sql += 'WHERE e.created_by = ?'; params = [req.user.id]; }
  else if (req.user.role === 'OWNER') {
    sql += 'WHERE (t.owner_id = ? OR (e.trip_id IS NULL AND (u.owner_id = ? OR e.created_by = ?)))';
    params = [req.user.id, req.user.id, req.user.id];
  }
  if (req.query.tripId) { sql += (params.length ? ' AND' : ' WHERE') + ' e.trip_id = ?'; params.push(req.query.tripId); }
  if (req.query.truckId) {
    sql += (params.length ? ' AND' : ' WHERE') +
      ' (t.truck_id = ? OR (e.trip_id IS NULL AND EXISTS (SELECT 1 FROM trucks tk WHERE tk.id = ? AND tk.driver_id = e.created_by)))';
    params.push(req.query.truckId, req.query.truckId);
  }
  sql += ' ORDER BY e.created_at DESC';
  const [rows] = await pool.query(sql, params);
  res.json({ success: true, expenses: rows });
});

r.post('/', auth, async (req, res) => {
  const { categoryId, amount, description, voiceText } = req.body;
  let { tripId } = req.body;
  tripId = tripId || null;

  if (req.user.role === 'DRIVER') {
    const [activeTrips] = await pool.query(
      "SELECT id FROM trips WHERE driver_id = ? AND status != 'COMPLETED'",
      [req.user.id]
    );
    if (activeTrips.length > 0) {
      if (!tripId) return res.status(400).json({ success: false, message: 'Select a trip for this expense — you have an active trip in progress' });
      const isActiveTrip = activeTrips.some(t => t.id == tripId);
      if (!isActiveTrip) return res.status(400).json({ success: false, message: 'Trip is not one of your active trips' });
    } else if (tripId) {
      const [[owned]] = await pool.query('SELECT id FROM trips WHERE id = ? AND driver_id = ?', [tripId, req.user.id]);
      if (!owned) return res.status(400).json({ success: false, message: 'Trip not found' });
    }
  }

  const status = req.user.role === 'OWNER' ? 'APPROVED' : 'PENDING';
  const approvedBy = status === 'APPROVED' ? req.user.id : null;
  const approvedAt = status === 'APPROVED' ? new Date() : null;
  const [result] = await pool.query(`
    INSERT INTO expenses(trip_id, created_by, category_id, amount, description, voice_text, status, approved_by, approved_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [tripId, req.user.id, categoryId, amount, description, voiceText, status, approvedBy, approvedAt]
  );
  const [rows] = await pool.query('SELECT * FROM expenses WHERE id = ?', [result.insertId]);
  res.status(201).json({ success: true, expense: rows[0] });
});

r.post('/:id/receipt', auth, upload.single('receipt'), async (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'receipt file required' });
  const url = '/uploads/receipts/' + req.file.filename;
  let sql = 'UPDATE expenses SET receipt_url = ? WHERE id = ?';
  const params = [url, req.params.id];
  if (req.user.role === 'DRIVER') { sql += ' AND created_by = ?'; params.push(req.user.id); }
  const [result] = await pool.query(sql, params);
  const [rows] = await pool.query('SELECT * FROM expenses WHERE id = ?', [req.params.id]);
  res.json({ success: result.affectedRows > 0, expense: rows[0] || null });
});

r.post('/:id/approve', auth, role('OWNER', 'ADMIN'), async (req, res) => {
  let sql = `UPDATE expenses e
             LEFT JOIN trips t ON t.id = e.trip_id
             JOIN users u ON u.id = e.created_by
             SET e.status = 'APPROVED', e.approved_by = ?, e.approved_at = NOW()
             WHERE e.id = ?`;
  const params = [req.user.id, req.params.id];
  if (req.user.role === 'OWNER') {
    sql += ' AND (t.owner_id = ? OR (e.trip_id IS NULL AND u.owner_id = ?))';
    params.push(req.user.id, req.user.id);
  }
  const [result] = await pool.query(sql, params);
  const [rows] = await pool.query('SELECT * FROM expenses WHERE id = ?', [req.params.id]);
  res.json({ success: result.affectedRows > 0, expense: rows[0] || null });
});

r.post('/:id/reject', auth, role('OWNER', 'ADMIN'), async (req, res) => {
  let sql = `UPDATE expenses e
             LEFT JOIN trips t ON t.id = e.trip_id
             JOIN users u ON u.id = e.created_by
             SET e.status = 'REJECTED', e.rejection_reason = ?
             WHERE e.id = ?`;
  const params = [req.body.reason || 'Rejected by owner', req.params.id];
  if (req.user.role === 'OWNER') {
    sql += ' AND (t.owner_id = ? OR (e.trip_id IS NULL AND u.owner_id = ?))';
    params.push(req.user.id, req.user.id);
  }
  const [result] = await pool.query(sql, params);
  const [rows] = await pool.query('SELECT * FROM expenses WHERE id = ?', [req.params.id]);
  res.json({ success: result.affectedRows > 0, expense: rows[0] || null });
});
export default r;
