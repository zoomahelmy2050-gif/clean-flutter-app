# Troubleshooting Guide

## Quick Fixes

### App Won't Start
```bash
# Clear Flutter cache
flutter clean
flutter pub get
flutter run

# If still not working
rm -rf .dart_tool/
rm pubspec.lock
flutter pub get
```

### Build Errors
```bash
# iOS specific
cd ios
pod deintegrate
pod install
cd ..

# Android specific
cd android
./gradlew clean
./gradlew build
cd ..
```

## Authentication Issues

### Cannot Sign In

#### Error: "Invalid credentials"
**Causes:**
- Incorrect email or password
- Account doesn't exist
- Account deactivated

**Solutions:**
1. Verify email address (check for typos)
2. Use "Forgot Password" to reset
3. Check if account is active
4. Try clearing app data

#### Error: "Account locked"
**Causes:**
- Too many failed login attempts
- Security policy violation
- Admin action

**Solutions:**
1. Wait 30 minutes for auto-unlock
2. Contact administrator
3. Use account recovery option
4. Check email for unlock instructions

### Two-Factor Authentication Issues

#### TOTP Codes Not Working
**Problem:** 6-digit codes are rejected
**Solutions:**
1. **Check device time:**
   ```
   Settings > Date & Time > Set Automatically
   ```
2. **Resync authenticator app:**
   - Google Authenticator: Settings > Time correction
   - Authy: Settings > Accounts > Sync
3. **Use backup codes**
4. **Regenerate TOTP secret**

#### Lost Access to 2FA Device
**Recovery Steps:**
1. Use backup codes to login
2. Go to Security Settings
3. Disable 2FA
4. Re-enable with new device
5. Generate new backup codes

### Session Problems

#### Frequent Logouts
**Causes:**
- Session timeout settings
- Network instability
- Multiple device conflicts

**Solutions:**
1. Increase session timeout:
   ```
   Settings > Security > Session Timeout > 60 minutes
   ```
2. Check network connection
3. Review active sessions
4. Enable "Remember Me"

## Performance Issues

### App Running Slowly

#### Mobile Devices
**Solutions:**
1. **Clear cache:**
   ```
   Settings > Storage > Clear Cache
   ```
2. **Reduce sync frequency:**
   ```
   Settings > Sync > Every 30 minutes
   ```
3. **Disable animations:**
   ```
   Settings > Appearance > Animations > Off
   ```
4. **Free up storage:** Remove unnecessary data
5. **Update app:** Check for latest version

#### Desktop/Web
**Solutions:**
1. Clear browser cache (Ctrl+Shift+Delete)
2. Disable browser extensions
3. Use hardware acceleration
4. Close unnecessary tabs
5. Update browser

### High Battery Consumption
**Solutions:**
1. Reduce background sync
2. Disable location services
3. Lower notification frequency
4. Use dark theme
5. Disable auto-backup

### Memory Issues
**Symptoms:** App crashes, freezes, or restarts
**Solutions:**
1. Close other apps
2. Restart device
3. Clear app cache
4. Reduce data retention period
5. Uninstall and reinstall

## Sync & Backup Issues

### Data Not Syncing

#### Check Sync Status
```
Settings > Sync > Status
```

**Common Fixes:**
1. **Force sync:**
   ```
   Settings > Sync > Sync Now
   ```
2. **Check permissions:**
   - Storage permission
   - Network permission
   - Background data
3. **Verify connectivity:**
   - Wi-Fi or mobile data
   - VPN settings
   - Firewall rules
4. **Re-authenticate:**
   - Sign out
   - Clear app data
   - Sign in again

### Backup Failures

#### Error: "Backup failed"
**Solutions:**
1. Check storage space (need 100MB free)
2. Verify network connection
3. Check backup permissions
4. Try manual backup
5. Change backup location

#### Restore Not Working
**Steps:**
1. Verify backup file integrity
2. Check file format (.backup)
3. Ensure correct encryption password
4. Try older backup
5. Contact support with backup ID

## Security Features Issues

### Vulnerability Scan Problems

#### Scan Stuck or Frozen
**Solutions:**
1. Cancel current scan
2. Clear scan cache
3. Restart app
4. Run quick scan first
5. Check system resources

#### False Positives
**Managing false positives:**
1. Review detection details
2. Whitelist if legitimate
3. Update threat definitions
4. Report to security team
5. Adjust sensitivity settings

### Audit Logs Missing

#### No Logs Appearing
**Check:**
1. Logging enabled in settings
2. Correct date range selected
3. Proper permissions (admin)
4. Storage space available
5. Database connectivity

## Notification Issues

### Not Receiving Notifications

#### Mobile
**Solutions:**
1. **Check permissions:**
   ```
   Settings > Apps > Security App > Notifications > Allow
   ```
2. **Disable battery optimization:**
   ```
   Settings > Battery > App Launch > Manual
   ```
3. **Check Do Not Disturb**
4. **Re-register push tokens:**
   ```
   Settings > Notifications > Reset Push
   ```

#### Email Notifications
**Check:**
1. Email address correct
2. Not in spam folder
3. Email preferences enabled
4. SMTP settings configured
5. Firewall not blocking

### Too Many Notifications
**Solutions:**
1. Adjust notification settings
2. Set quiet hours
3. Group notifications
4. Disable non-critical alerts
5. Use digest mode

## Network & Connectivity

### Connection Errors

#### Error: "Network timeout"
**Solutions:**
1. Check internet connection
2. Try different network
3. Disable VPN temporarily
4. Check proxy settings
5. Verify firewall rules

#### SSL/TLS Errors
**Common fixes:**
1. Update system date/time
2. Clear SSL state
3. Update certificates
4. Check proxy certificates
5. Disable certificate pinning (dev only)

### API Errors

#### Error 401: Unauthorized
**Meaning:** Authentication failed
**Fix:** Re-login or refresh token

#### Error 403: Forbidden
**Meaning:** Insufficient permissions
**Fix:** Check user role/permissions

#### Error 429: Too Many Requests
**Meaning:** Rate limit exceeded
**Fix:** Wait and retry

#### Error 500: Server Error
**Meaning:** Backend issue
**Fix:** Wait and report if persistent

## Database Issues

### Data Corruption
**Symptoms:** Crashes, missing data, errors
**Recovery:**
1. Export remaining data
2. Clear app data
3. Reinstall app
4. Import backup
5. Rebuild database

### Migration Failures
**During updates:**
1. Backup data first
2. Clear cache
3. Update incrementally
4. Check logs for errors
5. Manual migration if needed

## Platform-Specific Issues

### iOS Issues

#### Keychain Access Problems
**Fix:**
```bash
# Reset keychain
Settings > Security > Reset Keychain
```

#### Face ID Not Working
**Solutions:**
1. Re-enroll Face ID
2. Update iOS
3. Check app permissions
4. Reset face data

### Android Issues

#### Storage Permission Denied
**Fix:**
```
Settings > Apps > Permissions > Storage > Allow
```

#### Biometric Authentication Failed
**Solutions:**
1. Re-register fingerprints
2. Clear biometric data
3. Use alternative method
4. Check sensor cleanliness

### Windows Issues

#### Windows Defender Blocking
**Solutions:**
1. Add app to exclusions
2. Temporarily disable real-time protection
3. Check quarantine
4. Update definitions

### Web Browser Issues

#### LocalStorage Full
**Fix:**
```javascript
// Clear in browser console
localStorage.clear();
sessionStorage.clear();
```

#### WebSocket Connection Failed
**Solutions:**
1. Check browser compatibility
2. Disable ad blockers
3. Allow WebSocket in firewall
4. Try different browser

## Error Code Reference

### Authentication Errors (1xxx)
- **1001**: Invalid credentials
- **1002**: Account locked
- **1003**: Password expired
- **1004**: 2FA required
- **1005**: Session expired

### Network Errors (2xxx)
- **2001**: Connection timeout
- **2002**: No internet
- **2003**: SSL error
- **2004**: Proxy error
- **2005**: DNS resolution failed

### Data Errors (3xxx)
- **3001**: Data corruption
- **3002**: Sync conflict
- **3003**: Storage full
- **3004**: Backup failed
- **3005**: Restore failed

### Security Errors (4xxx)
- **4001**: Permission denied
- **4002**: Certificate invalid
- **4003**: Encryption failed
- **4004**: Signature verification failed
- **4005**: Token expired

### System Errors (5xxx)
- **5001**: Out of memory
- **5002**: Disk full
- **5003**: CPU overload
- **5004**: Service unavailable
- **5005**: Update required

## Debug Mode

### Enabling Debug Mode
```
Settings > Advanced > Developer Options > Debug Mode
```

### Collecting Debug Logs
1. Enable debug mode
2. Reproduce issue
3. Go to Settings > Logs
4. Export logs
5. Share with support

### Debug Information Includes:
- Device information
- App version
- Error stack traces
- Network requests
- Performance metrics
- User actions

## Getting Support

### Before Contacting Support
1. Check this guide
2. Update to latest version
3. Try basic troubleshooting
4. Collect error details
5. Document steps to reproduce

### Information to Provide
- App version
- Device/OS version
- Error messages
- Screenshots
- Debug logs
- Steps to reproduce
- When issue started
- What changed recently

### Support Channels
- **In-App**: Help > Contact Support
- **Email**: support@securityapp.com
- **Forum**: community.securityapp.com
- **Status**: status.securityapp.com

### Response Times
- **Critical**: 1 hour
- **High**: 4 hours
- **Medium**: 24 hours
- **Low**: 48 hours

## Preventive Measures

### Regular Maintenance
- Update app monthly
- Clear cache weekly
- Review permissions quarterly
- Test backups monthly
- Check security settings

### Best Practices
- Keep OS updated
- Use stable network
- Maintain free storage (10%)
- Regular password changes
- Monitor unusual activity

---

For additional help, see [User Guide](./USER_GUIDE.md) or [Features Guide](./FEATURES_GUIDE.md).
