const express = require('express');
const {
  getNotifications, getUnreadCount, markAsRead,
  markAllAsRead, deleteNotification
} = require('../controllers/notification.controller');
const { requireAuth } = require('../middleware/auth.middleware');

const router = express.Router();

router.get('/', requireAuth, getNotifications);
router.get('/count', requireAuth, getUnreadCount);
router.put('/read-all', requireAuth, markAllAsRead);
router.put('/:id/read', requireAuth, markAsRead);
router.delete('/:id', requireAuth, deleteNotification);

module.exports = router;
