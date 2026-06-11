const mongoose = require('mongoose');

const optionSchema = new mongoose.Schema({
  id: { type: String, required: true },
  name: { type: String },
  description: { type: String },
  votes: { type: Number, default: 0 }
});

const pollSchema = new mongoose.Schema({
  title: { type: String, required: true },
  mealTime: { type: String, enum: ['Breakfast', 'Lunch', 'Dinner'], required: true },
  date: { type: Date, required: true },
  messId: { type: String, ref: 'Mess', required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  vegOptions: [optionSchema],
  nonVegOptions: [optionSchema],
  fastOptions: [optionSchema],
  totalVeg: { type: Number, default: 0 },
  totalNonVeg: { type: Number, default: 0 },
  totalFast: { type: Number, default: 0 },
  totalNotComing: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  isFinalized: { type: Boolean, default: false },
  finalizedVeg: { type: String, default: null },
  finalizedNonVeg: { type: String, default: null },
  finalizedFast: { type: String, default: null },
  closesAt: { type: Date }
}, { timestamps: true });

module.exports = mongoose.model('Poll', pollSchema);
