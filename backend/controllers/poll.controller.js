const Poll = require('../models/Poll');
const KitchenOrder = require('../models/KitchenOrder');
const { createBulkNotifications, getStudentIdsInMess } = require('../utils/notificationHelper');
const { updateAttendanceForPoll } = require('../utils/attendanceHelper');

exports.createPoll = async (req, res, next) => {
  try {
    const { title, mealTime, vegOptions, nonVegOptions, fastOptions, closesAt } = req.body;

    const date = new Date();
    date.setHours(0, 0, 0, 0);

    const poll = await Poll.create({
      title,
      mealTime,
      date,
      messId: req.user.messId,
      createdBy: req.user.id,
      vegOptions,
      nonVegOptions,
      fastOptions,
      closesAt
    });

    const studentIds = await getStudentIdsInMess(req.user.messId);
    await createBulkNotifications(
      studentIds,
      req.user.messId,
      'poll_opened',
      'New Poll Available! 🍽️',
      `${poll.mealTime} poll is now open. Cast your vote!`,
      { pollId: poll._id }
    );

    res.status(201).json({ success: true, poll });
  } catch (err) {
    next(err);
  }
};

exports.getActivePolls = async (req, res, next) => {
  try {
    const polls = await Poll.find({ messId: req.user.messId, isActive: true }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, polls });
  } catch (err) {
    next(err);
  }
};

exports.getPollHistory = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const Vote = require('../models/Vote');
    const userVotes = await Vote.find({ userId: req.user.id }).select('pollId');
    const userPollIds = userVotes.map(v => v.pollId);

    const query = { 
      _id: { $in: userPollIds },
      messId: req.user.messId, 
      isFinalized: true 
    };
    
    const polls = await Poll.find(query).sort({ date: -1, createdAt: -1 }).skip(skip).limit(limit);
    const total = await Poll.countDocuments(query);

    res.status(200).json({ 
      success: true, 
      polls, 
      total, 
      page, 
      pages: Math.ceil(total / limit) 
    });
  } catch (err) {
    next(err);
  }
};

exports.getAllAdminPolls = async (req, res, next) => {
  try {
    const { status } = req.query;
    const filter = { messId: req.user.messId };
    
    if (status === 'active') filter.isActive = true;
    else if (status === 'finalized') filter.isFinalized = true;

    const polls = await Poll.find(filter).sort({ createdAt: -1 });
    res.status(200).json({ success: true, polls });
  } catch (err) {
    next(err);
  }
};

exports.getPollById = async (req, res, next) => {
  try {
    const poll = await Poll.findById(req.params.id);
    if (!poll) return res.status(404).json({ success: false, message: 'Poll not found' });

    if (poll.messId.toString() !== req.user.messId.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    res.status(200).json({ success: true, poll });
  } catch (err) {
    next(err);
  }
};

exports.finalizePoll = async (req, res, next) => {
  try {
    const poll = await Poll.findById(req.params.id);
    if (!poll) return res.status(404).json({ success: false, message: 'Poll not found' });
    
    if (poll.messId.toString() !== req.user.messId.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    if (poll.isFinalized) {
      return res.status(400).json({ success: false, message: 'Poll is already finalized' });
    }

    const topVeg = poll.vegOptions.length ? poll.vegOptions.reduce((max, opt) => opt.votes > max.votes ? opt : max) : null;
    const topNonVeg = poll.nonVegOptions.length ? poll.nonVegOptions.reduce((max, opt) => opt.votes > max.votes ? opt : max) : null;
    const topFast = poll.fastOptions.length ? poll.fastOptions.reduce((max, opt) => opt.votes > max.votes ? opt : max) : null;

    poll.isFinalized = true;
    poll.isActive = false;
    poll.finalizedVeg = topVeg ? topVeg.name : null;
    poll.finalizedNonVeg = topNonVeg ? topNonVeg.name : null;
    poll.finalizedFast = topFast ? topFast.name : null;

    await poll.save();

    const totalMeals = poll.totalVeg + poll.totalNonVeg + poll.totalFast;
    
    const kitchenOrder = await KitchenOrder.create({
      pollId: poll._id,
      messId: poll.messId,
      mealTime: poll.mealTime,
      date: poll.date,
      vegCount: poll.totalVeg,
      nonVegCount: poll.totalNonVeg,
      fastCount: poll.totalFast,
      notComingCount: poll.totalNotComing,
      finalVegMenu: poll.finalizedVeg,
      finalNonVegMenu: poll.finalizedNonVeg,
      finalFastMenu: poll.finalizedFast,
      totalMeals
    });

    const studentIds = await getStudentIdsInMess(req.user.messId);
    await createBulkNotifications(
      studentIds,
      req.user.messId,
      'poll_finalized',
      'Menu Finalized! 🎉',
      `${poll.mealTime} menu: Veg: ${poll.finalizedVeg || 'N/A'} | Non-Veg: ${poll.finalizedNonVeg || 'N/A'}`,
      { pollId: poll._id }
    );

    await updateAttendanceForPoll(poll);

    res.status(200).json({ success: true, poll, kitchenOrder });
  } catch (err) {
    next(err);
  }
};

exports.deletePoll = async (req, res, next) => {
  try {
    const poll = await Poll.findById(req.params.id);
    if (!poll) return res.status(404).json({ success: false, message: 'Poll not found' });
    
    if (poll.messId.toString() !== req.user.messId.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    if (poll.isFinalized) {
      return res.status(400).json({ success: false, message: 'Cannot delete a finalized poll' });
    }

    await poll.deleteOne();
    res.status(200).json({ success: true, message: 'Poll deleted successfully' });
  } catch (err) {
    next(err);
  }
};
