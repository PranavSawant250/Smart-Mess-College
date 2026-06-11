const express = require('express');
const { castVote, getMyVote, getPollVotes } = require('../controllers/vote.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin, requireStudent } = require('../middleware/role.middleware');

const router = express.Router();

router.post('/', requireAuth, requireStudent, castVote);
router.get('/my', requireAuth, requireStudent, getMyVote);
router.get('/poll/:pollId', requireAuth, requireAdmin, getPollVotes);

module.exports = router;
