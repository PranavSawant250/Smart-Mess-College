const express = require('express');
const {
  createAnnouncement, getAnnouncements, getAdminAnnouncements, deleteAnnouncement
} = require('../controllers/announcement.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin, requireStudent } = require('../middleware/role.middleware');

const router = express.Router();

router.post('/', requireAuth, requireAdmin, createAnnouncement);
router.get('/', requireAuth, requireStudent, getAnnouncements);
router.get('/admin', requireAuth, requireAdmin, getAdminAnnouncements);
router.delete('/:id', requireAuth, requireAdmin, deleteAnnouncement);

module.exports = router;
