const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');

// Load env vars
dotenv.config();

// Connect to database
connectDB();

const app = express();

// Middleware
app.use(express.json());
app.use(cors({ origin: '*' }));

// Route files
const authRouter = require('./routes/auth.routes');
const messRouter = require('./routes/mess.routes');
const pollRouter = require('./routes/poll.routes');
const voteRouter = require('./routes/vote.routes');
const feedbackRouter = require('./routes/feedback.routes');
const kitchenOrderRouter = require('./routes/kitchenOrder.routes');
const notificationRouter = require('./routes/notification.routes');
const announcementRouter = require('./routes/announcement.routes');
const attendanceRouter = require('./routes/attendance.routes');

// Mount routers
app.use('/api/auth', authRouter);
app.use('/api/mess', messRouter);
app.use('/api/polls', pollRouter);
app.use('/api/votes', voteRouter);
app.use('/api/feedback', feedbackRouter);
app.use('/api/kitchen-orders', kitchenOrderRouter);
app.use('/api/notifications', notificationRouter);
app.use('/api/announcements', announcementRouter);
app.use('/api/attendance', attendanceRouter);

// Initialize cron jobs
require('./utils/cronJobs');

// Global 404 handler
app.use((req, res, next) => {
  res.status(404).json({ success: false, message: 'Endpoint not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err);
  if (err.code === 11000) {
    return res.status(409).json({ success: false, message: 'Already exists (duplicate key error)' });
  }
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error'
  });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
});
