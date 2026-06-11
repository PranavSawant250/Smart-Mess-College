const Attendance = require('../models/Attendance');

exports.getMyAttendance = async (req, res, next) => {
  try {
    const now = new Date();
    const month = parseInt(req.query.month) || (now.getMonth() + 1);
    const year = parseInt(req.query.year) || now.getFullYear();

    const attendance = await Attendance.findOne({
      userId: req.user.id,
      messId: req.user.messId,
      month,
      year
    });

    if (!attendance) {
      return res.status(200).json({ 
        success: true, 
        attendance: {
          totalMeals: 0, attendedMeals: 0, skippedMeals: 0,
          missedMeals: 0, attendancePercentage: 0, billAmount: 0,
          records: []
        } 
      });
    }

    res.status(200).json({ success: true, attendance });
  } catch (err) {
    next(err);
  }
};

exports.getAttendanceSummary = async (req, res, next) => {
  try {
    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();

    const thisMonthAttendance = await Attendance.findOne({
      userId: req.user.id,
      messId: req.user.messId,
      month: currentMonth,
      year: currentYear
    });

    const allAttendances = await Attendance.find({
      userId: req.user.id,
      messId: req.user.messId
    });

    let totalMealsAllTime = 0;
    let attendedMealsAllTime = 0;

    allAttendances.forEach(a => {
      totalMealsAllTime += a.totalMeals;
      attendedMealsAllTime += a.attendedMeals;
    });

    const summary = {
      thisMonth: thisMonthAttendance ? {
        attended: thisMonthAttendance.attendedMeals,
        skipped: thisMonthAttendance.skippedMeals,
        missed: thisMonthAttendance.missedMeals,
        percentage: thisMonthAttendance.attendancePercentage,
        billAmount: thisMonthAttendance.billAmount
      } : {
        attended: 0, skipped: 0, missed: 0, percentage: 0, billAmount: 0
      },
      allTime: {
        totalMeals: totalMealsAllTime,
        attended: attendedMealsAllTime
      }
    };

    res.status(200).json({ success: true, summary });
  } catch (err) {
    next(err);
  }
};

exports.getStudentsAttendance = async (req, res, next) => {
  try {
    const now = new Date();
    const month = parseInt(req.query.month) || (now.getMonth() + 1);
    const year = parseInt(req.query.year) || now.getFullYear();

    const attendances = await Attendance.find({
      messId: req.user.messId,
      month,
      year
    }).populate('userId', 'name email rollNumber');

    const students = attendances.map(a => ({
      user: a.userId,
      attendance: {
        totalMeals: a.totalMeals,
        attendedMeals: a.attendedMeals,
        skippedMeals: a.skippedMeals,
        missedMeals: a.missedMeals,
        attendancePercentage: a.attendancePercentage,
        billAmount: a.billAmount
      }
    }));

    res.status(200).json({ success: true, students });
  } catch (err) {
    next(err);
  }
};

exports.getStudentAttendanceById = async (req, res, next) => {
  try {
    const now = new Date();
    const month = parseInt(req.query.month) || (now.getMonth() + 1);
    const year = parseInt(req.query.year) || now.getFullYear();

    const attendance = await Attendance.findOne({
      userId: req.params.id,
      messId: req.user.messId,
      month,
      year
    }).populate('userId', 'name email rollNumber');

    if (!attendance) {
      return res.status(404).json({ success: false, message: 'Attendance record not found' });
    }

    const student = attendance.userId;
    const attData = attendance.toObject();
    delete attData.userId;

    res.status(200).json({ success: true, student, attendance: attData });
  } catch (err) {
    next(err);
  }
};

exports.getAnalytics = async (req, res, next) => {
  try {
    const now = new Date();
    const month = parseInt(req.query.month) || (now.getMonth() + 1);
    const year = parseInt(req.query.year) || now.getFullYear();

    const attendances = await Attendance.find({
      messId: req.user.messId,
      month,
      year
    });

    let totalPresent = 0;
    let totalAbsent = 0;

    attendances.forEach(a => {
      totalPresent += a.attendedMeals;
      totalAbsent += a.skippedMeals + a.missedMeals;
    });

    const total = totalPresent + totalAbsent;
    const percentage = total > 0 ? ((totalPresent / total) * 100).toFixed(2) : 0;

    res.status(200).json({ 
      success: true, 
      totalPresent, 
      totalAbsent, 
      percentage: parseFloat(percentage) 
    });
  } catch (err) {
    next(err);
  }
};
