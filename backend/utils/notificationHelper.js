const Notification = require('../models/Notification');
const User = require('../models/User');

const createNotification = async (userId, messId, type, title, body, data = {}) => {
  return await Notification.create({ userId, messId, type, title, body, data });
};

const createBulkNotifications = async (userIds, messId, type, title, body, data = {}) => {
  const docs = userIds.map(uid => ({ userId: uid, messId, type, title, body, data }));
  return await Notification.insertMany(docs);
};

const getStudentIdsInMess = async (messId) => {
  const students = await User.find({ messId, role: 'student', isActive: true }).select('_id');
  return students.map(s => s._id);
};

module.exports = { createNotification, createBulkNotifications, getStudentIdsInMess };
