const express = require('express');
const { getKitchenOrders, getOrderById, getOrderByPollId } = require('../controllers/kitchenOrder.controller');
const { requireAuth } = require('../middleware/auth.middleware');
const { requireAdmin } = require('../middleware/role.middleware');

const router = express.Router();

router.get('/', requireAuth, requireAdmin, getKitchenOrders);
router.get('/:id', requireAuth, requireAdmin, getOrderById);
router.get('/poll/:pollId', requireAuth, requireAdmin, getOrderByPollId);

module.exports = router;
