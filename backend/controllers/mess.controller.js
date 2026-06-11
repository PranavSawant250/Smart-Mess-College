const Mess = require('../models/Mess');
const JoinRequest = require('../models/JoinRequest');
const User = require('../models/User');

exports.searchMess = async (req, res, next) => {
  try {
    const { name } = req.query;
    if (!name) return res.status(400).json({ success: false, message: 'Name query parameter required' });

    const messes = await Mess.find({ 
      messName: { $regex: name, $options: 'i' }, 
      isActive: true 
    }).limit(10);

    res.status(200).json({ success: true, data: messes });
  } catch (err) {
    next(err);
  }
};

exports.joinRequest = async (req, res, next) => {
  try {
    const { messId } = req.body;
    
    const pendingRequest = await JoinRequest.findOne({ studentId: req.user.id, messId, status: 'pending' });
    if (pendingRequest) {
      return res.status(400).json({ success: false, message: 'You already have a pending request for this mess' });
    }

    const mess = await Mess.findById(messId);
    if (!mess) return res.status(404).json({ success: false, message: 'Mess not found' });

    const user = await User.findById(req.user.id);

    const request = await JoinRequest.create({
      studentId: req.user.id,
      studentName: user.name,
      studentEmail: user.email,
      studentPhone: user.phone,
      messId: mess._id,
      messName: mess.messName
    });

    res.status(201).json({ success: true, request });
  } catch (err) {
    next(err);
  }
};

exports.myRequest = async (req, res, next) => {
  try {
    const request = await JoinRequest.findOne({ studentId: req.user.id }).sort({ requestedAt: -1 }).populate('messId', 'messName');
    res.status(200).json({ success: true, request });
  } catch (err) {
    next(err);
  }
};

exports.getRequests = async (req, res, next) => {
  try {
    const { status } = req.query;
    const filter = { messId: req.user.messId };
    if (status) filter.status = status;

    const requests = await JoinRequest.find(filter).populate('studentId', 'name email phone rollNumber').sort({ requestedAt: -1 });
    
    // Format to match prompt expectations: { success: true, requests: [{ request, student }] }
    const formattedRequests = requests.map(req => ({
      request: req,
      student: req.studentId
    }));

    res.status(200).json({ success: true, requests: formattedRequests });
  } catch (err) {
    next(err);
  }
};

exports.approveRequest = async (req, res, next) => {
  try {
    const request = await JoinRequest.findById(req.params.id);
    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });

    if (request.messId.toString() !== req.user.messId.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    request.status = 'approved';
    request.respondedAt = Date.now();
    await request.save();

    const student = await User.findById(request.studentId);
    student.messId = request.messId;
    await student.save();

    // Create Notification (to be implemented with notificationHelper)

    res.status(200).json({ success: true, request });
  } catch (err) {
    next(err);
  }
};

exports.rejectRequest = async (req, res, next) => {
  try {
    const request = await JoinRequest.findById(req.params.id);
    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });

    if (request.messId.toString() !== req.user.messId.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    request.status = 'rejected';
    request.respondedAt = Date.now();
    await request.save();

    // Create Notification (to be implemented with notificationHelper)

    res.status(200).json({ success: true, request });
  } catch (err) {
    next(err);
  }
};

exports.getStudents = async (req, res, next) => {
  try {
    const students = await User.find({ messId: req.user.messId, role: 'student', isActive: true }).select('-password');
    res.status(200).json({ success: true, students });
  } catch (err) {
    next(err);
  }
};

exports.removeStudent = async (req, res, next) => {
  try {
    const student = await User.findOne({ _id: req.params.id, messId: req.user.messId, role: 'student' });
    if (!student) return res.status(404).json({ success: false, message: 'Student not found in your mess' });

    student.messId = null;
    await student.save();

    res.status(200).json({ success: true, message: 'Student removed from mess' });
  } catch (err) {
    next(err);
  }
};

exports.myMess = async (req, res, next) => {
  try {
    if (!req.user.messId) return res.status(404).json({ success: false, message: 'Not joined in any mess' });
    const mess = await Mess.findById(req.user.messId);
    res.status(200).json({ success: true, mess });
  } catch (err) {
    next(err);
  }
};

exports.updateMess = async (req, res, next) => {
  try {
    const { address, description, monthlyFee } = req.body;
    const mess = await Mess.findByIdAndUpdate(req.user.messId, {
      address, description, monthlyFee
    }, { new: true, runValidators: true });

    res.status(200).json({ success: true, mess });
  } catch (err) {
    next(err);
  }
};
