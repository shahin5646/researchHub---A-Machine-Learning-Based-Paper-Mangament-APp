import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user_profile.dart';
import '../../providers/social_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const EditProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _institutionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _scholarController = TextEditingController();
  final _orcidController = TextEditingController();
  final _researchGateController = TextEditingController();
  final _websiteController = TextEditingController();

  List<String> _researchInterests = [];
  final TextEditingController _interestController = TextEditingController();

  bool _isProfilePublic = true;
  bool _showEmail = false;
  bool _showInstitution = true;
  bool _isSaving = false;

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(userProfileProvider(widget.userId).future);
    if (profile != null && mounted) {
      setState(() {
        _usernameController.text = profile.username ?? '';
        _bioController.text = profile.bio ?? '';
        _institutionController.text = profile.institution ?? '';
        _departmentController.text = profile.department ?? '';
        _positionController.text = profile.position ?? '';
        _linkedinController.text = profile.linkedinUrl ?? '';
        _scholarController.text = profile.googleScholarUrl ?? '';
        _orcidController.text = profile.orcidId ?? '';
        _researchGateController.text = profile.researchGateUrl ?? '';
        _websiteController.text = profile.websiteUrl ?? '';
        _researchInterests = List.from(profile.researchInterests);
        _isProfilePublic = profile.isProfilePublic;
        _showEmail = profile.showEmail;
        _showInstitution = profile.showInstitution;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _institutionController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _linkedinController.dispose();
    _scholarController.dispose();
    _orcidController.dispose();
    _researchGateController.dispose();
    _websiteController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.userId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Picture Section
                _buildProfilePictureSection(profile),
                const SizedBox(height: 24),

                // Username Section
                _buildSectionTitle('Username'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Choose a unique username',
                    prefixText: '@',
                    border: const OutlineInputBorder(),
                    helperText: 'Your unique handle, like Instagram',
                  ),
                  maxLength: 30,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is required';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
                      return 'Only letters, numbers, dots and underscores allowed';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Bio Section
                _buildSectionTitle('About'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 24),

                // Academic Info Section
                _buildSectionTitle('Academic Information'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _institutionController,
                  decoration: const InputDecoration(
                    labelText: 'Institution',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    hintText: 'e.g., Professor, PhD Student',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Research Interests Section
                _buildSectionTitle('Research Interests'),
                const SizedBox(height: 8),
                _buildResearchInterestsSection(),
                const SizedBox(height: 24),

                // Social Links Section
                _buildSectionTitle('Academic Links'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _linkedinController,
                  decoration: const InputDecoration(
                    labelText: 'LinkedIn URL',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _scholarController,
                  decoration: const InputDecoration(
                    labelText: 'Google Scholar URL',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _orcidController,
                  decoration: const InputDecoration(
                    labelText: 'ORCID ID',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _researchGateController,
                  decoration: const InputDecoration(
                    labelText: 'ResearchGate URL',
                    prefixIcon: Icon(Icons.science),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Personal Website',
                    prefixIcon: Icon(Icons.language),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 24),

                // Privacy Settings Section
                _buildSectionTitle('Privacy Settings'),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Public Profile'),
                  subtitle: const Text('Anyone can view your profile'),
                  value: _isProfilePublic,
                  onChanged: (value) {
                    setState(() {
                      _isProfilePublic = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Show Email'),
                  subtitle: const Text('Display email on your profile'),
                  value: _showEmail,
                  onChanged: (value) {
                    setState(() {
                      _showEmail = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Show Institution'),
                  subtitle: const Text('Display your institution'),
                  value: _showInstitution,
                  onChanged: (value) {
                    setState(() {
                      _showInstitution = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildProfilePictureSection(UserProfile profile) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (profile.photoURL != null
                        ? NetworkImage(profile.photoURL!) as ImageProvider
                        : null),
                child: _selectedImage == null && profile.photoURL == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: theme.colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                    onPressed: _pickImage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload),
            label: const Text('Change Photo'),
          ),
        ],
      ),
    );
  }

  Widget _buildResearchInterestsSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _interestController,
                decoration: const InputDecoration(
                  labelText: 'Add Interest',
                  hintText: 'e.g., Machine Learning',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => _addInterest(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addInterest,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_researchInterests.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _researchInterests.map((interest) {
              return Chip(
                label: Text(interest),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeInterest(interest),
                backgroundColor: theme.colorScheme.primaryContainer,
              );
            }).toList(),
          ),
      ],
    );
  }

  void _addInterest() {
    final interest = _interestController.text.trim();
    if (interest.isNotEmpty && !_researchInterests.contains(interest)) {
      setState(() {
        _researchInterests.add(interest);
        _interestController.clear();
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _researchInterests.remove(interest);
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final service = ref.read(socialProfileServiceProvider);
      final currentProfile =
          await ref.read(userProfileProvider(widget.userId).future);

      if (currentProfile == null) {
        throw Exception('Profile not found');
      }

      // Upload profile picture if selected
      String? photoURL = currentProfile.photoURL;
      if (_selectedImage != null) {
        photoURL = await service.uploadProfilePicture(
          widget.userId,
          _selectedImage!,
        );
      }

      // Update profile
      final updatedProfile = currentProfile.copyWith(
        username: _usernameController.text.trim(),
        photoURL: photoURL,
        bio: _bioController.text.trim(),
        institution: _institutionController.text.trim(),
        department: _departmentController.text.trim(),
        position: _positionController.text.trim(),
        researchInterests: _researchInterests,
        linkedinUrl: _linkedinController.text.trim(),
        googleScholarUrl: _scholarController.text.trim(),
        orcidId: _orcidController.text.trim(),
        researchGateUrl: _researchGateController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        isProfilePublic: _isProfilePublic,
        showEmail: _showEmail,
        showInstitution: _showInstitution,
        updatedAt: DateTime.now(),
      );

      await service.updateUserProfile(widget.userId, updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
