const mongoose = require('mongoose');

const announcementSchema = new mongoose.Schema({
  messId: { type: String, ref: 'Mess', required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  title: { type: String, required: true, maxlength: 100 },
  body: { type: String, required: true, maxlength: 1000 },
  type: { type: String, enum: ['general', 'holiday', 'special_meal', 'mess_closed'] },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Announcement', announcementSchema);
