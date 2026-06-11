const express = require('express');
const {
  signupStudent, signupAdmin, login, biometricLogin,
  getMe, updateProfile, biometricEnable, changePassword, logout
} = require('../controllers/auth.controller');
const { requireAuth } = require('../middleware/auth.middleware');

const router = express.Router();

router.post('/signup/student', signupStudent);
router.post('/signup/admin', signupAdmin);
router.post('/login', login);
router.post('/biometric-login', biometricLogin);

router.get('/me', requireAuth, getMe);
router.put('/profile', requireAuth, updateProfile);
router.put('/biometric-enable', requireAuth, biometricEnable);
router.put('/change-password', requireAuth, changePassword);
router.post('/logout', requireAuth, logout);

module.exports = router;
