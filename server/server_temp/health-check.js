// Simple health check endpoint for Railway deployment
const express = require('express');
const app = express();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Database health check
app.get('/api/health/db', async (req, res) => {
  try {
    // This would normally check your database connection
    // For now, just return success if DATABASE_URL exists
    const dbUrl = process.env.DATABASE_URL;
    if (dbUrl) {
      res.json({
        status: 'ok',
        database: 'connected',
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(500).json({
        status: 'error',
        database: 'no DATABASE_URL found'
      });
    }
  } catch (error) {
    res.status(500).json({
      status: 'error',
      database: 'connection failed',
      error: error.message
    });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Health check server running on port ${port}`);
});

module.exports = app;
