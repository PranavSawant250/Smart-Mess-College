const cron = require('node-cron');
const Poll = require('../models/Poll');
const User = require('../models/User');
const Feedback = require('../models/Feedback');
const { createNotification } = require('./notificationHelper');

// Job: feedbackReminderJob (Runs every day at 11:00 PM)
cron.schedule('0 23 * * *', async () => {
  try {
    const twelveHoursAgo = new Date(Date.now() - 12 * 3600 * 1000);
    const polls = await Poll.find({ isFinalized: true, updatedAt: { $gte: twelveHoursAgo } });

    for (const poll of polls) {
      const students = await User.find({ messId: poll.messId, role: 'student', isActive: true });
      
      const timeDiffHours = (Date.now() - poll.date.getTime()) / (1000 * 3600);
      const hoursLeft = Math.max(0, Math.floor(48 - timeDiffHours));

      if (hoursLeft <= 0) continue;

      for (const student of students) {
        const hasFeedback = await Feedback.findOne({ userId: student._id, pollId: poll._id });
        if (!hasFeedback) {
          await createNotification(
            student._id,
            poll.messId,
            'feedback_reminder',
            'Feedback Reminder ⭐',
            `Don't forget to rate today's ${poll.mealTime}! Window closes in ${hoursLeft} hours.`,
            { pollId: poll._id }
          );
        }
      }
    }
  } catch (err) {
    console.error('Error in feedbackReminderJob:', err);
  }
});

// Job: autoClosePollsJob (every 6 hours)
cron.schedule('0 */6 * * *', async () => {
  try {
    const now = new Date();
    await Poll.updateMany(
      { closesAt: { $ne: null, $lte: now }, isActive: true },
      { $set: { isActive: false } }
    );
  } catch (err) {
    console.error('Error in autoClosePollsJob:', err);
  }
});

module.exports = {};
