const Feedback = require('../models/Feedback');
const Poll = require('../models/Poll');

exports.submitFeedback = async (req, res, next) => {
  try {
    const { pollId, foodQuality, taste, service, comment } = req.body;

    const poll = await Poll.findById(pollId);
    if (!poll) return res.status(404).json({ success: false, message: 'Poll not found' });
    if (!poll.isFinalized) return res.status(400).json({ success: false, message: 'Poll must be finalized' });

    if (poll.messId.toString() !== req.user.messId.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    const timeDiffHours = (Date.now() - poll.date.getTime()) / (1000 * 3600);
    if (timeDiffHours > 48) {
      return res.status(400).json({ success: false, message: 'Feedback window expired' });
    }

    const feedback = await Feedback.create({
      userId: req.user.id,
      userName: req.user.name || 'Student',
      pollId,
      messId: req.user.messId,
      foodQuality,
      taste,
      service,
      comment
    });

    res.status(201).json({ success: true, feedback });
  } catch (err) {
    next(err);
  }
};

exports.getPollFeedbacks = async (req, res, next) => {
  try {
    const feedbacks = await Feedback.find({ pollId: req.params.pollId, messId: req.user.messId }).populate('userId', 'name rollNumber');
    res.status(200).json({ success: true, feedbacks });
  } catch (err) {
    next(err);
  }
};

exports.getMessFeedbacks = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const query = { messId: req.user.messId };
    const feedbacks = await Feedback.find(query)
      .sort({ submittedAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('userId', 'name rollNumber')
      .populate('pollId', 'title date mealTime');
    
    const total = await Feedback.countDocuments(query);
    
    let avgFoodQuality = 0, avgTaste = 0, avgService = 0, avgOverall = 0;
    
    if (feedbacks.length > 0) {
      let sumFoodQuality = 0, sumTaste = 0, sumService = 0;
      feedbacks.forEach(f => {
        sumFoodQuality += f.foodQuality;
        sumTaste += f.taste;
        sumService += f.service;
      });
      avgFoodQuality = sumFoodQuality / feedbacks.length;
      avgTaste = sumTaste / feedbacks.length;
      avgService = sumService / feedbacks.length;
      avgOverall = (avgFoodQuality + avgTaste + avgService) / 3;
    }

    const summary = { avgFoodQuality, avgTaste, avgService, avgOverall };

    res.status(200).json({ success: true, feedbacks, total, summary });
  } catch (err) {
    next(err);
  }
};

exports.getFeedbackSummary = async (req, res, next) => {
  try {
    const feedbacks = await Feedback.find({ messId: req.user.messId });
    const count = feedbacks.length;
    
    let avgFoodQuality = 0, avgTaste = 0, avgService = 0, avgOverall = 0;
    
    if (count > 0) {
      let sumFoodQuality = 0, sumTaste = 0, sumService = 0;
      feedbacks.forEach(f => {
        sumFoodQuality += f.foodQuality;
        sumTaste += f.taste;
        sumService += f.service;
      });
      avgFoodQuality = sumFoodQuality / count;
      avgTaste = sumTaste / count;
      avgService = sumService / count;
      avgOverall = (avgFoodQuality + avgTaste + avgService) / 3;
    }

    const summary = { avgFoodQuality, avgTaste, avgService, avgOverall, count };
    res.status(200).json({ success: true, summary });
  } catch (err) {
    next(err);
  }
};

exports.getMyFeedbackStatus = async (req, res, next) => {
  try {
    const { pollId } = req.params;
    const poll = await Poll.findById(pollId);
    
    if (!poll) return res.status(404).json({ success: false, message: 'Poll not found' });

    const feedback = await Feedback.findOne({ userId: req.user.id, pollId });
    const hasSubmitted = !!feedback;
    
    const timeDiffHours = (Date.now() - poll.date.getTime()) / (1000 * 3600);
    const windowOpen = timeDiffHours <= 48;
    const hoursLeft = Math.max(0, 48 - timeDiffHours);

    res.status(200).json({ success: true, hasSubmitted, feedback, windowOpen, hoursLeft });
  } catch (err) {
    next(err);
  }
};
