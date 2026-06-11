const mongoose = require('mongoose');

const voteSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  pollId: { type: mongoose.Schema.Types.ObjectId, ref: 'Poll', required: true },
  messId: { type: String, ref: 'Mess', required: true },
  mealType: { type: String, enum: ['veg', 'nonVeg', 'fast', 'skip'], required: true },
  optionId: { type: String, default: null },
  isComing: { type: Boolean, default: true },
  votedAt: { type: Date, default: Date.now }
});

voteSchema.index({ userId: 1, pollId: 1 }, { unique: true });

module.exports = mongoose.model('Vote', voteSchema);
