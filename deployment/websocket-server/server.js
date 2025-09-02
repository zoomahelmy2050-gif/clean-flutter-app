const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const redis = require('redis');
const cors = require('cors');
const helmet = require('helmet');
const winston = require('winston');
const { Pool } = require('pg');

// Configure logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Configure CORS
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true
};

app.use(cors(corsOptions));
app.use(helmet());
app.use(express.json());

// Initialize Socket.IO
const io = socketIo(server, {
  cors: corsOptions,
  transports: ['websocket', 'polling']
});

// Initialize Redis client
const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
  password: process.env.REDIS_PASSWORD
});

redisClient.on('error', (err) => {
  logger.error('Redis Client Error:', err);
});

redisClient.connect();

// Initialize PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// JWT Authentication middleware
const authenticateSocket = async (socket, next) => {
  try {
    const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.split(' ')[1];
    
    if (!token) {
      return next(new Error('Authentication token required'));
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Verify user exists and is active
    const userResult = await pool.query(
      'SELECT id, email, is_active FROM security.users WHERE id = $1 AND is_active = true',
      [decoded.userId]
    );

    if (userResult.rows.length === 0) {
      return next(new Error('Invalid user or user inactive'));
    }

    socket.userId = decoded.userId;
    socket.userEmail = userResult.rows[0].email;
    
    logger.info(`User authenticated: ${socket.userEmail} (${socket.userId})`);
    next();
  } catch (error) {
    logger.error('Socket authentication error:', error);
    next(new Error('Authentication failed'));
  }
};

// Apply authentication middleware
io.use(authenticateSocket);

// Socket connection handling
io.on('connection', (socket) => {
  logger.info(`User connected: ${socket.userEmail} (${socket.id})`);

  // Join user to their personal room
  socket.join(`user_${socket.userId}`);
  
  // Join user to role-based rooms
  socket.join('authenticated_users');

  // Handle subscription to specific event types
  socket.on('subscribe', (eventTypes) => {
    if (Array.isArray(eventTypes)) {
      eventTypes.forEach(eventType => {
        socket.join(`events_${eventType}`);
        logger.info(`User ${socket.userEmail} subscribed to ${eventType}`);
      });
    }
  });

  // Handle unsubscription
  socket.on('unsubscribe', (eventTypes) => {
    if (Array.isArray(eventTypes)) {
      eventTypes.forEach(eventType => {
        socket.leave(`events_${eventType}`);
        logger.info(`User ${socket.userEmail} unsubscribed from ${eventType}`);
      });
    }
  });

  // Handle heartbeat
  socket.on('ping', () => {
    socket.emit('pong');
  });

  // Handle security event acknowledgment
  socket.on('acknowledge_event', async (data) => {
    try {
      const { eventId, notes } = data;
      
      await pool.query(
        'UPDATE security.security_events SET resolved = true, resolved_at = CURRENT_TIMESTAMP, resolved_by = $1 WHERE id = $2',
        [socket.userId, eventId]
      );

      // Log the acknowledgment
      await logAuditEvent(socket.userId, 'acknowledge_security_event', 'security_event', eventId, socket);

      socket.emit('event_acknowledged', { eventId, success: true });
      logger.info(`Event ${eventId} acknowledged by ${socket.userEmail}`);
    } catch (error) {
      logger.error('Error acknowledging event:', error);
      socket.emit('event_acknowledged', { eventId: data.eventId, success: false, error: error.message });
    }
  });

  // Handle threat alert acknowledgment
  socket.on('acknowledge_threat', async (data) => {
    try {
      const { alertId, notes } = data;
      
      await pool.query(
        'UPDATE security.threat_alerts SET acknowledged = true, acknowledged_at = CURRENT_TIMESTAMP, acknowledged_by = $1 WHERE id = $2',
        [socket.userId, alertId]
      );

      await logAuditEvent(socket.userId, 'acknowledge_threat_alert', 'threat_alert', alertId, socket);

      socket.emit('threat_acknowledged', { alertId, success: true });
      logger.info(`Threat alert ${alertId} acknowledged by ${socket.userEmail}`);
    } catch (error) {
      logger.error('Error acknowledging threat:', error);
      socket.emit('threat_acknowledged', { alertId: data.alertId, success: false, error: error.message });
    }
  });

  // Handle device action requests
  socket.on('device_action', async (data) => {
    try {
      const { deviceId, action, reason } = data;
      
      // Log the device action
      await pool.query(
        'INSERT INTO security.security_events (user_id, event_type, event_category, severity, description, metadata) VALUES ($1, $2, $3, $4, $5, $6)',
        [
          socket.userId,
          'device_action_requested',
          'device_management',
          'medium',
          `Device action requested: ${action} on device ${deviceId}`,
          JSON.stringify({ deviceId, action, reason })
        ]
      );

      // Emit to device management service
      io.to('device_managers').emit('device_action_request', {
        deviceId,
        action,
        reason,
        requestedBy: socket.userId,
        requestedAt: new Date().toISOString()
      });

      socket.emit('device_action_queued', { deviceId, action, success: true });
      logger.info(`Device action ${action} queued for device ${deviceId} by ${socket.userEmail}`);
    } catch (error) {
      logger.error('Error processing device action:', error);
      socket.emit('device_action_queued', { deviceId: data.deviceId, action: data.action, success: false, error: error.message });
    }
  });

  // Handle disconnection
  socket.on('disconnect', (reason) => {
    logger.info(`User disconnected: ${socket.userEmail} (${socket.id}) - Reason: ${reason}`);
  });

  // Handle connection errors
  socket.on('error', (error) => {
    logger.error(`Socket error for user ${socket.userEmail}:`, error);
  });
});

// Broadcast functions for external services
const broadcastSecurityEvent = async (event) => {
  try {
    // Store in Redis for persistence
    await redisClient.setEx(`event_${event.id}`, 3600, JSON.stringify(event));
    
    // Broadcast to all authenticated users
    io.to('authenticated_users').emit('security_event', event);
    
    // Broadcast to specific event type subscribers
    io.to(`events_${event.event_type}`).emit('security_event', event);
    
    logger.info(`Security event broadcasted: ${event.event_type}`);
  } catch (error) {
    logger.error('Error broadcasting security event:', error);
  }
};

const broadcastThreatAlert = async (alert) => {
  try {
    await redisClient.setEx(`alert_${alert.id}`, 3600, JSON.stringify(alert));
    
    io.to('authenticated_users').emit('threat_alert', alert);
    io.to(`events_threat_intelligence`).emit('threat_alert', alert);
    
    logger.info(`Threat alert broadcasted: ${alert.alert_type}`);
  } catch (error) {
    logger.error('Error broadcasting threat alert:', error);
  }
};

const broadcastComplianceEvent = async (event) => {
  try {
    await redisClient.setEx(`compliance_${event.id}`, 3600, JSON.stringify(event));
    
    io.to('authenticated_users').emit('compliance_event', event);
    io.to(`events_compliance`).emit('compliance_event', event);
    
    logger.info(`Compliance event broadcasted: ${event.violation_type}`);
  } catch (error) {
    logger.error('Error broadcasting compliance event:', error);
  }
};

const broadcastDeviceEvent = async (event) => {
  try {
    await redisClient.setEx(`device_${event.device_id}`, 3600, JSON.stringify(event));
    
    io.to('authenticated_users').emit('device_event', event);
    io.to(`events_device_management`).emit('device_event', event);
    
    // Send to specific user if device belongs to them
    if (event.user_id) {
      io.to(`user_${event.user_id}`).emit('device_event', event);
    }
    
    logger.info(`Device event broadcasted: ${event.event_type} for device ${event.device_id}`);
  } catch (error) {
    logger.error('Error broadcasting device event:', error);
  }
};

// Audit logging helper
const logAuditEvent = async (userId, action, resourceType, resourceId, socket) => {
  try {
    await pool.query(
      'INSERT INTO security.audit_logs (user_id, action, resource_type, resource_id, ip_address, user_agent) VALUES ($1, $2, $3, $4, $5, $6)',
      [
        userId,
        action,
        resourceType,
        resourceId,
        socket.handshake.address,
        socket.handshake.headers['user-agent']
      ]
    );
  } catch (error) {
    logger.error('Error logging audit event:', error);
  }
};

// REST API endpoints for external services
app.post('/api/events/security', async (req, res) => {
  try {
    const event = req.body;
    await broadcastSecurityEvent(event);
    res.json({ success: true, message: 'Security event broadcasted' });
  } catch (error) {
    logger.error('Error in security event endpoint:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/events/threat', async (req, res) => {
  try {
    const alert = req.body;
    await broadcastThreatAlert(alert);
    res.json({ success: true, message: 'Threat alert broadcasted' });
  } catch (error) {
    logger.error('Error in threat alert endpoint:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/events/compliance', async (req, res) => {
  try {
    const event = req.body;
    await broadcastComplianceEvent(event);
    res.json({ success: true, message: 'Compliance event broadcasted' });
  } catch (error) {
    logger.error('Error in compliance event endpoint:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/events/device', async (req, res) => {
  try {
    const event = req.body;
    await broadcastDeviceEvent(event);
    res.json({ success: true, message: 'Device event broadcasted' });
  } catch (error) {
    logger.error('Error in device event endpoint:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    connections: io.engine.clientsCount
  });
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    const metrics = {
      active_connections: io.engine.clientsCount,
      redis_connected: redisClient.isReady,
      database_connected: pool.totalCount > 0,
      uptime: process.uptime(),
      memory_usage: process.memoryUsage(),
      timestamp: new Date().toISOString()
    };
    res.json(metrics);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully');
  
  server.close(() => {
    logger.info('HTTP server closed');
  });
  
  await redisClient.quit();
  await pool.end();
  
  process.exit(0);
});

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  logger.info(`WebSocket server running on port ${PORT}`);
});
