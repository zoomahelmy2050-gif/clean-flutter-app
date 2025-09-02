import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../locator.dart';
import '../auth/services/auth_service.dart';
import '../../core/services/user_profile_service.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final _authService = locator<AuthService>();
  final _profileService = locator<UserProfileService>();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  String? _currentUser;

  // Profile data
  String? _profileImageUrl;
  DateTime? _dateOfBirth;
  String _gender = '';
  String _timezone = 'UTC';
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load from local storage first for immediate display
      await _loadFromLocalStorage();
      
      // Then try to sync with backend in background
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final success = await _profileService.loadUserProfile(currentUser);
        
        if (success && _profileService.currentProfile != null) {
          final profile = _profileService.currentProfile!;
          _updateControllersFromProfile(profile);
          setState(() {});
        } else {
          // Fallback to local storage if backend fails
          await _loadFromLocalStorage();
        }
      } else {
        // Load from local storage if no user
        await _loadFromLocalStorage();
      }
    } catch (e) {
      // Fallback to local storage on error
      await _loadFromLocalStorage();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using offline data: ${_profileService.error ?? e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = 'personal_info_${_currentUser ?? 'default'}';
    final personalData = prefs.getString(userKey);

    if (personalData != null) {
      final jsonData = json.decode(personalData);
      _firstNameController.text = jsonData['firstName'] ?? '';
      _lastNameController.text = jsonData['lastName'] ?? '';
      _emailController.text = jsonData['email'] ?? '';
      _phoneController.text = jsonData['phone'] ?? '';
      _bioController.text = jsonData['bio'] ?? '';
      _locationController.text = jsonData['location'] ?? '';
      _websiteController.text = jsonData['website'] ?? '';
      _dateOfBirth = DateTime.tryParse(jsonData['dateOfBirth'] ?? '');
      _gender = jsonData['gender'] ?? '';
      _timezone = jsonData['timezone'] ?? 'UTC';
      _language = jsonData['language'] ?? 'English';
    } else {
      // Default values
      _firstNameController.text = 'John';
      _lastNameController.text = 'Doe';
      _emailController.text = _currentUser ?? 'user@example.com';
      _phoneController.text = '+1 (555) 123-4567';
      _bioController.text = 'Software developer passionate about security and privacy.';
      _locationController.text = 'San Francisco, CA';
      _websiteController.text = 'https://johndoe.dev';
      _dateOfBirth = DateTime(1990, 5, 15);
      _gender = 'Prefer not to say';
      _timezone = 'America/Los_Angeles';
      _language = 'English';
      _profileImageUrl = null;
    }
  }

  Future<void> _savePersonalInformation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare profile data
      final profileData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'bio': _bioController.text,
        'location': _locationController.text,
        'website': _websiteController.text,
        'gender': _gender,
        'timezone': _timezone,
        'language': _language,
      };

      // Try to save to backend first
      bool success = false;
      if (_currentUser != null) {
        success = await _profileService.updateUserProfile(profileData);
      }

      if (success) {
        // Also save to local storage as backup
        await _saveToLocalStorage(profileData);
        
        setState(() {
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Personal information saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Save to local storage only if backend fails
        await _saveToLocalStorage(profileData);
        
        setState(() {
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved offline: ${_profileService.error ?? 'Backend unavailable'}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Fallback to local storage
      final profileData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'bio': _bioController.text,
        'location': _locationController.text,
        'website': _websiteController.text,
        'gender': _gender,
        'timezone': _timezone,
        'language': _language,
      };
      
      await _saveToLocalStorage(profileData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved offline due to error: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveToLocalStorage(Map<String, dynamic> profileData) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = 'personal_info_${_currentUser ?? 'default'}';
    profileData['lastUpdated'] = DateTime.now().toIso8601String();
    await prefs.setString(userKey, json.encode(profileData));
  }

  void _updateControllersFromProfile(dynamic profile) {
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _emailController.text = profile.email ?? '';
    _phoneController.text = profile.phone ?? '';
    _bioController.text = profile.bio ?? '';
    _locationController.text = profile.location ?? '';
    _websiteController.text = profile.website ?? '';
    
    if (profile.dateOfBirth != null) {
      _dateOfBirth = DateTime.tryParse(profile.dateOfBirth.toString());
    }
    
    _gender = profile.gender ?? '';
    _timezone = profile.timezone ?? 'UTC';
    _language = profile.language ?? 'English';
    _profileImageUrl = profile.profileImageUrl;
  }

  void _discardChanges() {
    setState(() {
      _isEditing = false;
    });
    _loadUserProfile();
  }

  Future<void> _selectDateOfBirth() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _dateOfBirth = date;
      });
    }
  }

  Future<void> _changeProfileImage() async {
    // Mock image picker - in real app, use image_picker package
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Picture'),
        content: const Text(
          'This feature would open the image picker to select a new profile picture.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile picture updated!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Select Image'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _isLoading ? null : _discardChanges,
            ),
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              onPressed: _isLoading ? null : _savePersonalInformation,
            ),
          ],
        ],
      ),
      body: _isLoading && !_isEditing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                    ? NetworkImage(_profileImageUrl!)
                                    : null,
                                child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                                    ? const Icon(Icons.person, size: 60)
                                    : null,
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                      ),
                                      onPressed: _changeProfileImage,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_firstNameController.text} ${_lastNameController.text}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _emailController.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Basic Information
                    Text(
                      'Basic Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'First Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    enabled: _isEditing,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'First name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Last Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    enabled: _isEditing,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Last name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              enabled:
                                  false, // Email should not be editable here
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              enabled: _isEditing,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _isEditing ? _selectDateOfBirth : null,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date of Birth',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _dateOfBirth != null
                                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                      : 'Select date of birth',
                                  style: TextStyle(
                                    color: _dateOfBirth != null
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _gender.isNotEmpty ? _gender : null,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('Male'),
                                ),
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('Female'),
                                ),
                                DropdownMenuItem(
                                  value: 'Non-binary',
                                  child: Text('Non-binary'),
                                ),
                                DropdownMenuItem(
                                  value: 'Prefer not to say',
                                  child: Text('Prefer not to say'),
                                ),
                              ],
                              onChanged: _isEditing
                                  ? (value) {
                                      setState(() {
                                        _gender = value ?? '';
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Additional Information
                    Text(
                      'Additional Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _bioController,
                              decoration: const InputDecoration(
                                labelText: 'Bio',
                                hintText: 'Tell us about yourself',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.info_outline),
                              ),
                              enabled: _isEditing,
                              maxLines: 3,
                              maxLength: 500,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: 'Location',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _websiteController,
                              decoration: const InputDecoration(
                                labelText: 'Website',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.link),
                              ),
                              enabled: _isEditing,
                              keyboardType: TextInputType.url,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final uri = Uri.tryParse(value);
                                  if (uri == null || !uri.hasAbsolutePath) {
                                    return 'Please enter a valid URL';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Preferences
                    Text(
                      'Preferences',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _timezone,
                              decoration: const InputDecoration(
                                labelText: 'Timezone',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'UTC',
                                  child: Text('UTC'),
                                ),
                                DropdownMenuItem(
                                  value: 'America/New_York',
                                  child: Text('Eastern Time'),
                                ),
                                DropdownMenuItem(
                                  value: 'America/Chicago',
                                  child: Text('Central Time'),
                                ),
                                DropdownMenuItem(
                                  value: 'America/Denver',
                                  child: Text('Mountain Time'),
                                ),
                                DropdownMenuItem(
                                  value: 'America/Los_Angeles',
                                  child: Text('Pacific Time'),
                                ),
                                DropdownMenuItem(
                                  value: 'Europe/London',
                                  child: Text('London'),
                                ),
                                DropdownMenuItem(
                                  value: 'Europe/Paris',
                                  child: Text('Paris'),
                                ),
                                DropdownMenuItem(
                                  value: 'Asia/Tokyo',
                                  child: Text('Tokyo'),
                                ),
                              ],
                              onChanged: _isEditing
                                  ? (value) {
                                      setState(() {
                                        _timezone = value ?? 'UTC';
                                      });
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _language,
                              decoration: const InputDecoration(
                                labelText: 'Language',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.language),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'English',
                                  child: Text('English'),
                                ),
                                DropdownMenuItem(
                                  value: 'Spanish',
                                  child: Text('Spanish'),
                                ),
                                DropdownMenuItem(
                                  value: 'French',
                                  child: Text('French'),
                                ),
                                DropdownMenuItem(
                                  value: 'German',
                                  child: Text('German'),
                                ),
                                DropdownMenuItem(
                                  value: 'Italian',
                                  child: Text('Italian'),
                                ),
                                DropdownMenuItem(
                                  value: 'Portuguese',
                                  child: Text('Portuguese'),
                                ),
                                DropdownMenuItem(
                                  value: 'Japanese',
                                  child: Text('Japanese'),
                                ),
                                DropdownMenuItem(
                                  value: 'Chinese',
                                  child: Text('Chinese'),
                                ),
                              ],
                              onChanged: _isEditing
                                  ? (value) {
                                      setState(() {
                                        _language = value ?? 'English';
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Account Information
                    if (!_isEditing) ...[
                      Text(
                        'Account Information',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                'Account Created',
                                'January 15, 2024',
                              ),
                              const Divider(),
                              _buildInfoRow('Last Updated', 'Today'),
                              const Divider(),
                              _buildInfoRow(
                                'Account Status',
                                'Active',
                                valueColor: Colors.green,
                              ),
                              const Divider(),
                              _buildInfoRow(
                                'Email Verified',
                                'Yes',
                                valueColor: Colors.green,
                              ),
                              const Divider(),
                              _buildInfoRow(
                                'Phone Verified',
                                'Yes',
                                valueColor: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
