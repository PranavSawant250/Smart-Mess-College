const Vote = require('../models/Vote');
const Poll = require('../models/Poll');

exports.castVote = async (req, res, next) => {
  try {
    const { pollId, mealType, optionId, isComing } = req.body;

    const poll = await Poll.findById(pollId);
    if (!poll) return res.status(404).json({ success: false, message: 'Poll not found' });
    if (!poll.isActive) return res.status(400).json({ success: false, message: 'Poll is not active' });

    if (poll.messId.toString() !== req.user.messId.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    const vote = await Vote.create({
      userId: req.user.id,
      pollId,
      messId: req.user.messId,
      mealType,
      optionId: isComing ? optionId : null,
      isComing
    });

    let incUpdate = {};
    if (mealType === 'veg') {
      incUpdate = { totalVeg: 1, 'vegOptions.$[elem].votes': 1 };
      await Poll.findByIdAndUpdate(pollId, { $inc: incUpdate }, { arrayFilters: [{ 'elem.id': optionId }] });
    } else if (mealType === 'nonVeg') {
      incUpdate = { totalNonVeg: 1, 'nonVegOptions.$[elem].votes': 1 };
      await Poll.findByIdAndUpdate(pollId, { $inc: incUpdate }, { arrayFilters: [{ 'elem.id': optionId }] });
    } else if (mealType === 'fast') {
      incUpdate = { totalFast: 1, 'fastOptions.$[elem].votes': 1 };
      await Poll.findByIdAndUpdate(pollId, { $inc: incUpdate }, { arrayFilters: [{ 'elem.id': optionId }] });
    } else if (mealType === 'skip') {
      await Poll.findByIdAndUpdate(pollId, { $inc: { totalNotComing: 1 } });
    }

    res.status(201).json({ success: true, vote });
  } catch (err) {
    next(err);
  }
};

exports.getMyVote = async (req, res, next) => {
  try {
    const { pollId } = req.query;
    if (!pollId) return res.status(400).json({ success: false, message: 'pollId is required' });

    const vote = await Vote.findOne({ userId: req.user.id, pollId });
    res.status(200).json({ success: true, vote });
  } catch (err) {
    next(err);
  }
};

exports.getPollVotes = async (req, res, next) => {
  try {
    const { pollId } = req.params;
    const poll = await Poll.findById(pollId);
    if (!poll || poll.messId.toString() !== req.user.messId.toString()) {
      return res.status(404).json({ success: false, message: 'Poll not found' });
    }

    const votes = await Vote.find({ pollId }).populate('userId', 'name email rollNumber');
    
    const summary = {
      totalVeg: poll.totalVeg,
      totalNonVeg: poll.totalNonVeg,
      totalFast: poll.totalFast,
      totalNotComing: poll.totalNotComing
    };

    res.status(200).json({ success: true, votes, summary });
  } catch (err) {
    next(err);
  }
};
