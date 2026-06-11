const express = require('express');
const {
  createPoll, getActivePolls, getPollHistory, getAllAdminPolls,
  getPollById, finalizePoll, deletePoll
} = require('../controllers/poll.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin, requireStudent } = require('../middleware/role.middleware');

const router = express.Router();

router.post('/', requireAuth, requireAdmin, createPoll);
router.get('/active', requireAuth, requireStudent, getActivePolls);
router.get('/history', requireAuth, requireStudent, getPollHistory);
router.get('/admin/all', requireAuth, requireAdmin, getAllAdminPolls);
router.get('/:id', requireAuth, getPollById);
router.put('/:id/finalize', requireAuth, requireAdmin, finalizePoll);
router.delete('/:id', requireAuth, requireAdmin, deletePoll);

module.exports = router;
