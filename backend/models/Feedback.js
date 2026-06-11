const mongoose = require('mongoose');

const feedbackSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  userName: { type: String },
  pollId: { type: mongoose.Schema.Types.ObjectId, ref: 'Poll', required: true },
  messId: { type: String, ref: 'Mess', required: true },
  foodQuality: { type: Number, required: true, min: 1, max: 5 },
  taste: { type: Number, required: true, min: 1, max: 5 },
  service: { type: Number, required: true, min: 1, max: 5 },
  comment: { type: String, maxlength: 500 },
  submittedAt: { type: Date, default: Date.now }
});

feedbackSchema.index({ userId: 1, pollId: 1 }, { unique: true });

module.exports = mongoose.model('Feedback', feedbackSchema);
