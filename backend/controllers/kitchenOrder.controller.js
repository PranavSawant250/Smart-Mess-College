const KitchenOrder = require('../models/KitchenOrder');

exports.getKitchenOrders = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const query = { messId: req.user.messId };
    const orders = await KitchenOrder.find(query)
      .sort({ sentAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('pollId', 'title');

    res.status(200).json({ success: true, orders });
  } catch (err) {
    next(err);
  }
};

exports.getOrderById = async (req, res, next) => {
  try {
    const order = await KitchenOrder.findById(req.params.id).populate('pollId', 'title');
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    
    if (order.messId.toString() !== req.user.messId.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    res.status(200).json({ success: true, order });
  } catch (err) {
    next(err);
  }
};

exports.getOrderByPollId = async (req, res, next) => {
  try {
    const order = await KitchenOrder.findOne({ pollId: req.params.pollId }).populate('pollId', 'title');
    if (!order) return res.status(404).json({ success: false, message: 'Order not found for this poll' });

    if (order.messId.toString() !== req.user.messId.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    res.status(200).json({ success: true, order });
  } catch (err) {
    next(err);
  }
};
