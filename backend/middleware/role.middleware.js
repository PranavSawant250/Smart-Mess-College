const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ success: false, message: 'Forbidden: Admin access required' });
  }
  next();
};

const requireStudent = (req, res, next) => {
  if (req.user.role !== 'student') {
    return res.status(403).json({ success: false, message: 'Forbidden: Student access required' });
  }
  next();
};

const requireSameMess = (req, res, next) => {
  // Usually implemented inside controllers where resource is loaded
  next();
};

module.exports = { requireAdmin, requireStudent, requireSameMess };
