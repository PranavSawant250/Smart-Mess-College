const express = require('express');
const {
  submitFeedback, getPollFeedbacks, getMessFeedbacks,
  getFeedbackSummary, getMyFeedbackStatus
} = require('../controllers/feedback.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin, requireStudent } = require('../middleware/role.middleware');

const router = express.Router();

router.post('/', requireAuth, requireStudent, submitFeedback);
router.get('/poll/:pollId', requireAuth, requireAdmin, getPollFeedbacks);
router.get('/mess', requireAuth, requireAdmin, getMessFeedbacks);
router.get('/summary', requireAuth, requireAdmin, getFeedbackSummary);
router.get('/my-status/:pollId', requireAuth, requireStudent, getMyFeedbackStatus);

module.exports = router;
