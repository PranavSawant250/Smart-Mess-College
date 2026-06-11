const Attendance = require('../models/Attendance');
const Vote = require('../models/Vote');
const User = require('../models/User');
const Mess = require('../models/Mess');

const updateAttendanceForPoll = async (poll) => {
  const students = await User.find({ messId: poll.messId, role: 'student', isActive: true });
  const mess = await Mess.findById(poll.messId);
  if (!mess) return;

  const month = poll.date.getMonth() + 1;
  const year = poll.date.getFullYear();

  for (const student of students) {
    const vote = await Vote.findOne({ userId: student._id, pollId: poll._id });
    let status = 'missed';
    if (vote) {
      status = vote.isComing ? 'attended' : 'skipped';
    }

    let attendance = await Attendance.findOne({
      userId: student._id, messId: poll.messId, month, year
    });

    if (!attendance) {
      attendance = new Attendance({
        userId: student._id, messId: poll.messId, month, year,
        totalMeals: 0, attendedMeals: 0, skippedMeals: 0, missedMeals: 0,
        records: []
      });
    }

    attendance.records.push({
      pollId: poll._id,
      date: poll.date,
      mealTime: poll.mealTime,
      status
    });

    attendance.totalMeals += 1;
    if (status === 'attended') attendance.attendedMeals += 1;
    else if (status === 'skipped') attendance.skippedMeals += 1;
    else if (status === 'missed') attendance.missedMeals += 1;

    attendance.attendancePercentage = (attendance.attendedMeals / attendance.totalMeals) * 100;
    // Calculate billAmount (prorated by attended meals vs total meals that month?
    // Wait, prompt says: attendedMeals × monthlyFee / totalMeals, 
    // or maybe attendedMeals / totalMeals of the whole month isn't known yet.
    // The prompt rule 11 says: Monthly bill = (attendedMeals / totalMeals) × mess.monthlyFee
    attendance.billAmount = (attendance.attendedMeals / attendance.totalMeals) * mess.monthlyFee;

    await attendance.save();
  }
};

module.exports = { updateAttendanceForPoll };
