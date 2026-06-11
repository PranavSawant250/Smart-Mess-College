const mongoose = require('mongoose');

const messSchema = new mongoose.Schema({
  _id: { 
    type: String, 
    required: true,
    match: [/^[A-Z]{2}\d{4}$/, 'Mess ID must be 2 uppercase letters followed by 4 digits (e.g., AB1234)']
  },
  messName: { type: String, required: true, unique: true, trim: true },
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  address: { type: String },
  description: { type: String },
  monthlyFee: { type: Number, default: 0, min: 0 },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

messSchema.index({ messName: 'text' });

module.exports = mongoose.model('Mess', messSchema);
