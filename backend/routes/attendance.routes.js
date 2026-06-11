const express = require('express');
const {
  getMyAttendance, getAttendanceSummary,
  getStudentsAttendance, getStudentAttendanceById, getAnalytics
} = require('../controllers/attendance.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin, requireStudent } = require('../middleware/role.middleware');

const router = express.Router();

router.get('/my', requireAuth, requireStudent, getMyAttendance);
router.get('/summary', requireAuth, requireStudent, getAttendanceSummary);
router.get('/students', requireAuth, requireAdmin, getStudentsAttendance);
router.get('/student/:id', requireAuth, requireAdmin, getStudentAttendanceById);
router.get('/analytics', requireAuth, requireAdmin, getAnalytics);

module.exports = router;
