const mongoose = require('mongoose');

const joinRequestSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  studentName: { type: String },
  studentEmail: { type: String },
  studentPhone: { type: String },
  messId: { type: String, ref: 'Mess', required: true },
  messName: { type: String },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  requestedAt: { type: Date, default: Date.now },
  respondedAt: { type: Date, default: null }
});

module.exports = mongoose.model('JoinRequest', joinRequestSchema);
