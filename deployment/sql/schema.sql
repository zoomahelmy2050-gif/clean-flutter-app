-- Security App Database Schema
-- Production-ready schema with indexes and constraints

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create security schema
CREATE SCHEMA IF NOT EXISTS security;

-- Users table with enhanced security
CREATE TABLE security.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    failed_login_attempts INTEGER DEFAULT 0,
    last_failed_login TIMESTAMP,
    account_locked_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    email_verified BOOLEAN DEFAULT false,
    two_factor_enabled BOOLEAN DEFAULT false,
    role VARCHAR(50) DEFAULT 'user'
);

-- User sessions for JWT management
CREATE TABLE security.user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES security.users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT true
);

-- Security events logging
CREATE TABLE security.security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES security.users(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    event_category VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'info',
    description TEXT NOT NULL,
    metadata JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMP,
    resolved_by UUID REFERENCES security.users(id)
);

-- Threat alerts from external sources
CREATE TABLE security.threat_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_type VARCHAR(100) NOT NULL,
    source VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    indicators JSONB,
    metadata JSONB,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    acknowledged BOOLEAN DEFAULT false,
    acknowledged_by UUID REFERENCES security.users(id),
    acknowledged_at TIMESTAMP
);

-- Compliance violations tracking
CREATE TABLE security.compliance_violations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    violation_type VARCHAR(100) NOT NULL,
    framework VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    affected_resource VARCHAR(255),
    remediation_steps TEXT,
    status VARCHAR(50) DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP,
    assigned_to UUID REFERENCES security.users(id),
    resolved_at TIMESTAMP,
    resolution_notes TEXT
);

-- Device management
CREATE TABLE security.devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id VARCHAR(255) UNIQUE NOT NULL,
    user_id UUID REFERENCES security.users(id) ON DELETE CASCADE,
    device_name VARCHAR(255),
    device_type VARCHAR(100),
    platform VARCHAR(100),
    os_version VARCHAR(100),
    app_version VARCHAR(100),
    is_enrolled BOOLEAN DEFAULT false,
    is_compliant BOOLEAN DEFAULT false,
    last_seen TIMESTAMP,
    enrollment_date TIMESTAMP,
    device_fingerprint JSONB,
    location_data JSONB,
    security_status JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Security policies
CREATE TABLE security.policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(255) NOT NULL,
    policy_type VARCHAR(100) NOT NULL,
    description TEXT,
    policy_rules JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    applies_to VARCHAR(100) DEFAULT 'all',
    created_by UUID REFERENCES security.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1
);

-- Forensic cases
CREATE TABLE security.forensic_cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_number VARCHAR(100) UNIQUE NOT NULL,
    case_title VARCHAR(255) NOT NULL,
    case_type VARCHAR(100) NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(50) DEFAULT 'open',
    description TEXT,
    assigned_investigator UUID REFERENCES security.users(id),
    created_by UUID REFERENCES security.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    case_metadata JSONB
);

-- Digital evidence storage
CREATE TABLE security.evidence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID NOT NULL REFERENCES security.forensic_cases(id) ON DELETE CASCADE,
    evidence_name VARCHAR(255) NOT NULL,
    evidence_type VARCHAR(100) NOT NULL,
    file_path VARCHAR(500),
    file_size BIGINT,
    file_hash VARCHAR(255),
    chain_of_custody JSONB,
    collected_by UUID REFERENCES security.users(id),
    collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    is_verified BOOLEAN DEFAULT false,
    verification_hash VARCHAR(255)
);

-- Cryptographic operations log
CREATE TABLE security.crypto_operations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operation_type VARCHAR(100) NOT NULL,
    key_id VARCHAR(255),
    algorithm VARCHAR(100),
    user_id UUID REFERENCES security.users(id),
    operation_metadata JSONB,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit trail for all operations
CREATE TABLE security.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES security.users(id),
    action VARCHAR(255) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(255),
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id UUID REFERENCES security.user_sessions(id)
);

-- API keys and tokens
CREATE TABLE security.api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    user_id UUID REFERENCES security.users(id) ON DELETE CASCADE,
    permissions JSONB,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP,
    last_used TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rate_limit INTEGER DEFAULT 1000
);

-- System configuration
CREATE TABLE security.system_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(255) UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    description TEXT,
    is_sensitive BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES security.users(id)
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON security.users(email);
CREATE INDEX idx_users_active ON security.users(is_active);
CREATE INDEX idx_sessions_token ON security.user_sessions(session_token);
CREATE INDEX idx_sessions_user_id ON security.user_sessions(user_id);
CREATE INDEX idx_sessions_expires ON security.user_sessions(expires_at);
CREATE INDEX idx_security_events_user_id ON security.security_events(user_id);
CREATE INDEX idx_security_events_type ON security.security_events(event_type);
CREATE INDEX idx_security_events_created ON security.security_events(created_at);
CREATE INDEX idx_threat_alerts_type ON security.threat_alerts(alert_type);
CREATE INDEX idx_threat_alerts_severity ON security.threat_alerts(severity);
CREATE INDEX idx_threat_alerts_status ON security.threat_alerts(status);
CREATE INDEX idx_compliance_violations_type ON security.compliance_violations(violation_type);
CREATE INDEX idx_compliance_violations_status ON security.compliance_violations(status);
CREATE INDEX idx_devices_user_id ON security.devices(user_id);
CREATE INDEX idx_devices_device_id ON security.devices(device_id);
CREATE INDEX idx_devices_enrolled ON security.devices(is_enrolled);
CREATE INDEX idx_forensic_cases_number ON security.forensic_cases(case_number);
CREATE INDEX idx_forensic_cases_status ON security.forensic_cases(status);
CREATE INDEX idx_evidence_case_id ON security.evidence(case_id);
CREATE INDEX idx_evidence_hash ON security.evidence(file_hash);
CREATE INDEX idx_crypto_ops_user_id ON security.crypto_operations(user_id);
CREATE INDEX idx_crypto_ops_type ON security.crypto_operations(operation_type);
CREATE INDEX idx_audit_logs_user_id ON security.audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON security.audit_logs(action);
CREATE INDEX idx_audit_logs_created ON security.audit_logs(created_at);
CREATE INDEX idx_api_keys_hash ON security.api_keys(key_hash);
CREATE INDEX idx_api_keys_user_id ON security.api_keys(user_id);

-- Create triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION security.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON security.users FOR EACH ROW EXECUTE FUNCTION security.update_updated_at_column();
CREATE TRIGGER update_threat_alerts_updated_at BEFORE UPDATE ON security.threat_alerts FOR EACH ROW EXECUTE FUNCTION security.update_updated_at_column();
CREATE TRIGGER update_compliance_violations_updated_at BEFORE UPDATE ON security.compliance_violations FOR EACH ROW EXECUTE FUNCTION security.update_updated_at_column();
CREATE TRIGGER update_devices_updated_at BEFORE UPDATE ON security.devices FOR EACH ROW EXECUTE FUNCTION security.update_updated_at_column();
CREATE TRIGGER update_policies_updated_at BEFORE UPDATE ON security.policies FOR EACH ROW EXECUTE FUNCTION security.update_updated_at_column();
CREATE TRIGGER update_forensic_cases_updated_at BEFORE UPDATE ON security.forensic_cases FOR EACH ROW EXECUTE FUNCTION security.update_updated_at_column();
CREATE TRIGGER update_system_config_updated_at BEFORE UPDATE ON security.system_config FOR EACH ROW EXECUTE FUNCTION security.update_updated_at_column();

-- Insert default system configuration
INSERT INTO security.system_config (config_key, config_value, description) VALUES
('max_failed_login_attempts', '5', 'Maximum failed login attempts before account lockout'),
('account_lockout_duration', '900', 'Account lockout duration in seconds (15 minutes)'),
('session_timeout', '3600', 'Session timeout in seconds (1 hour)'),
('password_min_length', '8', 'Minimum password length'),
('require_2fa', 'false', 'Require two-factor authentication for all users'),
('api_rate_limit', '1000', 'Default API rate limit per hour'),
('threat_alert_retention_days', '365', 'Days to retain threat alerts'),
('audit_log_retention_days', '2555', 'Days to retain audit logs (7 years)'),
('evidence_retention_years', '7', 'Years to retain digital evidence');

-- Create views for common queries
CREATE VIEW security.active_users AS
SELECT id, email, created_at, last_login, role
FROM security.users
WHERE is_active = true;

CREATE VIEW security.recent_security_events AS
SELECT se.*, u.email as user_email
FROM security.security_events se
LEFT JOIN security.users u ON se.user_id = u.id
WHERE se.created_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
ORDER BY se.created_at DESC;

CREATE VIEW security.active_threat_alerts AS
SELECT *
FROM security.threat_alerts
WHERE status = 'active' AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
ORDER BY severity DESC, created_at DESC;

CREATE VIEW security.open_compliance_violations AS
SELECT cv.*, u.email as assigned_to_email
FROM security.compliance_violations cv
LEFT JOIN security.users u ON cv.assigned_to = u.id
WHERE cv.status = 'open'
ORDER BY cv.severity DESC, cv.created_at ASC;

-- Grant permissions (adjust as needed for your security model)
GRANT USAGE ON SCHEMA security TO PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA security TO PUBLIC;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA security TO PUBLIC;
