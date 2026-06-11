const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  messId: { type: String, ref: 'Mess' },
  type: { 
    type: String, 
    enum: [
      'poll_opened', 
      'request_approved', 
      'request_rejected', 
      'poll_finalized', 
      'feedback_reminder', 
      'announcement', 
      'kitchen_order'
    ] 
  },
  title: { type: String },
  body: { type: String },
  data: { type: Object },
  isRead: { type: Boolean, default: false }
}, { timestamps: true });

notificationSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
