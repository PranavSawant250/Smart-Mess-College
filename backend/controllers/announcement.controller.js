const Announcement = require('../models/Announcement');
const { createBulkNotifications, getStudentIdsInMess } = require('../utils/notificationHelper');

exports.createAnnouncement = async (req, res, next) => {
  try {
    const { title, body, type } = req.body;

    const announcement = await Announcement.create({
      messId: req.user.messId,
      createdBy: req.user.id,
      title,
      body,
      type
    });

    const studentIds = await getStudentIdsInMess(req.user.messId);
    await createBulkNotifications(
      studentIds,
      req.user.messId,
      'announcement',
      title,
      body,
      { announcementId: announcement._id }
    );

    res.status(201).json({ success: true, announcement });
  } catch (err) {
    next(err);
  }
};

exports.getAnnouncements = async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const announcements = await Announcement.find({ messId: req.user.messId, isActive: true })
      .sort({ createdAt: -1 })
      .limit(limit);

    res.status(200).json({ success: true, announcements });
  } catch (err) {
    next(err);
  }
};

exports.getAdminAnnouncements = async (req, res, next) => {
  try {
    const announcements = await Announcement.find({ createdBy: req.user.id, isActive: true })
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, announcements });
  } catch (err) {
    next(err);
  }
};

exports.deleteAnnouncement = async (req, res, next) => {
  try {
    const announcement = await Announcement.findOneAndUpdate(
      { _id: req.params.id, messId: req.user.messId },
      { isActive: false },
      { new: true }
    );

    if (!announcement) return res.status(404).json({ success: false, message: 'Announcement not found' });

    res.status(200).json({ success: true, message: 'Announcement deleted' });
  } catch (err) {
    next(err);
  }
};
