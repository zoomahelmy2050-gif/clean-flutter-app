module.exports = {
  apps: [{
    name: 'e2ee-server',
    script: 'dist/main.js',
    cwd: 'c:/Users/Hazem/clean_flutter/server',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    log_file: 'logs/combined.log',
    out_file: 'logs/out.log',
    error_file: 'logs/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm Z'
  }]
};
