import jwt from 'jsonwebtoken';

export function auth(req,res,next) {
  const token = req.headers.authorization?.replace('Bearer ','');
  if (!token) return res.status(401).json({success:false,message:'Unauthorized'});
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({success:false,message:'Invalid token'});
  }
}

export const role = (...roles) => (req,res,next) =>
  roles.includes(req.user.role) ? next() : res.status(403).json({success:false,message:'Forbidden'});
