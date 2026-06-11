const mongoose = require('mongoose');

const recordSchema = new mongoose.Schema({
  pollId: { type: mongoose.Schema.Types.ObjectId },
  date: { type: Date },
  mealTime: { type: String },
  status: { type: String, enum: ['attended', 'skipped', 'missed'] }
});

const attendanceSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  messId: { type: String, ref: 'Mess', required: true },
  month: { type: Number, min: 1, max: 12 },
  year: { type: Number },
  totalMeals: { type: Number, default: 0 },
  attendedMeals: { type: Number, default: 0 },
  skippedMeals: { type: Number, default: 0 },
  missedMeals: { type: Number, default: 0 },
  attendancePercentage: { type: Number, default: 0 },
  billAmount: { type: Number, default: 0 },
  records: [recordSchema]
});

attendanceSchema.index({ userId: 1, messId: 1, month: 1, year: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);
