const express = require('express');
const {
  searchMess, joinRequest, myRequest, getRequests,
  approveRequest, rejectRequest, getStudents, removeStudent,
  myMess, updateMess
} = require('../controllers/mess.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin, requireStudent } = require('../middleware/role.middleware');

const router = express.Router();

router.get('/search', requireAuth, searchMess);
router.post('/join-request', requireAuth, requireStudent, joinRequest);
router.get('/my-request', requireAuth, requireStudent, myRequest);
router.get('/requests', requireAuth, requireAdmin, getRequests);
router.put('/requests/:id/approve', requireAuth, requireAdmin, approveRequest);
router.put('/requests/:id/reject', requireAuth, requireAdmin, rejectRequest);
router.get('/students', requireAuth, requireAdmin, getStudents);
router.delete('/students/:id', requireAuth, requireAdmin, removeStudent);
router.get('/my-mess', requireAuth, requireStudent, myMess);
router.put('/update', requireAuth, requireAdmin, updateMess);

module.exports = router;
