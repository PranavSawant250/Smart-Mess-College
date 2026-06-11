const mongoose = require('mongoose');

const kitchenOrderSchema = new mongoose.Schema({
  pollId: { type: mongoose.Schema.Types.ObjectId, ref: 'Poll', required: true, unique: true },
  messId: { type: String, ref: 'Mess', required: true },
  mealTime: { type: String },
  date: { type: Date },
  vegCount: { type: Number },
  nonVegCount: { type: Number },
  fastCount: { type: Number },
  notComingCount: { type: Number },
  finalVegMenu: { type: String },
  finalNonVegMenu: { type: String },
  finalFastMenu: { type: String },
  totalMeals: { type: Number },
  sentAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('KitchenOrder', kitchenOrderSchema);
