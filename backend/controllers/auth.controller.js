const User = require('../models/User');
const Mess = require('../models/Mess');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const signToken = (userId, role, messId) => {
  return jwt.sign({ userId, role, messId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d'
  });
};

exports.signupStudent = async (req, res, next) => {
  try {
    const { name, email, phone, password, rollNumber } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(409).json({ success: false, message: 'Email already in use' });

    const hashedPassword = await bcrypt.hash(password, parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12);

    const user = await User.create({
      name, email, phone, password: hashedPassword, role: 'student', rollNumber
    });

    const token = signToken(user._id, user.role, null);

    const userObj = user.toObject();
    delete userObj.password;

    res.status(201).json({ success: true, token, user: userObj });
  } catch (err) {
    next(err);
  }
};

exports.signupAdmin = async (req, res, next) => {
  try {
    const { name, email, phone, password, messName, messId, address, description, monthlyFee } = req.body;

    if (!messId || !/^[A-Z]{2}\d{4}$/.test(messId)) {
      return res.status(400).json({ success: false, message: 'Invalid Mess ID format. Must be 2 uppercase letters + 4 digits.' });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(409).json({ success: false, message: 'Email already in use' });

    const existingMess = await Mess.findOne({ $or: [{ messName }, { _id: messId }] });
    if (existingMess) return res.status(409).json({ success: false, message: 'Mess name or ID already in use' });

    const hashedPassword = await bcrypt.hash(password, parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12);

    const user = await User.create({
      name, email, phone, password: hashedPassword, role: 'admin'
    });

    const mess = await Mess.create({
      _id: messId, messName, adminId: user._id, address, description, monthlyFee
    });

    user.messId = mess._id;
    await user.save();

    const token = signToken(user._id, user.role, mess._id);

    const userObj = user.toObject();
    delete userObj.password;

    res.status(201).json({ success: true, token, user: userObj, mess });
  } catch (err) {
    next(err);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password, role } = req.body;

    const user = await User.findOne({ email, role });
    if (!user) return res.status(401).json({ success: false, message: 'Invalid credentials' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ success: false, message: 'Invalid credentials' });

    const token = signToken(user._id, user.role, user.messId);

    const userObj = user.toObject();
    delete userObj.password;

    let mess = null;
    if (user.role === 'admin' && user.messId) {
      mess = await Mess.findById(user.messId);
    } else if (user.role === 'student' && user.messId) {
       mess = await Mess.findById(user.messId);
    }

    res.status(200).json({ success: true, token, user: userObj, mess });
  } catch (err) {
    next(err);
  }
};

exports.biometricLogin = async (req, res, next) => {
  try {
    const { userId } = req.body;

    const user = await User.findById(userId);
    if (!user || !user.biometricEnabled) {
      return res.status(403).json({ success: false, message: 'Biometric login not enabled' });
    }

    const token = signToken(user._id, user.role, user.messId);
    const userObj = user.toObject();
    delete userObj.password;

    res.status(200).json({ success: true, token, user: userObj });
  } catch (err) {
    next(err);
  }
};

exports.getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    let mess = null;
    if (user.messId) {
      mess = await Mess.findById(user.messId);
    }

    res.status(200).json({ success: true, data: { user, mess } });
  } catch (err) {
    next(err);
  }
};

exports.updateProfile = async (req, res, next) => {
  try {
    const { name, phone, rollNumber, profilePicture } = req.body;

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { name, phone, rollNumber, profilePicture },
      { new: true, runValidators: true }
    ).select('-password');

    res.status(200).json({ success: true, user });
  } catch (err) {
    next(err);
  }
};

exports.biometricEnable = async (req, res, next) => {
  try {
    const { enabled } = req.body;
    await User.findByIdAndUpdate(req.user.id, { biometricEnabled: enabled });
    res.status(200).json({ success: true, message: `Biometric ${enabled ? 'enabled' : 'disabled'} successfully` });
  } catch (err) {
    next(err);
  }
};

exports.changePassword = async (req, res, next) => {
  try {
    const { oldPassword, newPassword } = req.body;
    const user = await User.findById(req.user.id);

    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) return res.status(401).json({ success: false, message: 'Incorrect old password' });

    user.password = await bcrypt.hash(newPassword, parseInt(process.env.BCRYPT_SALT_ROUNDS) || 12);
    await user.save();

    res.status(200).json({ success: true, message: 'Password changed successfully' });
  } catch (err) {
    next(err);
  }
};

exports.logout = async (req, res, next) => {
  res.status(200).json({ success: true, message: 'Logged out successfully' });
};
