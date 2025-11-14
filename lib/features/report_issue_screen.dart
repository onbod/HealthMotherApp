import 'package:flutter/material.dart';
import '../widgets/shared_app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/success_bottom_sheet.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  String? _selectedReportType;
  final _facilityNameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  final List<String> _reportTypes = [
    'Healthcare Worker Issue',
    'Facility Problem',
    'Service Quality',
    'Communication Issue',
    'Equipment Problem',
    'Other',
  ];
  Future<void> _pickImages() async {
    try {
      // Limit to 5 images total
      final remainingSlots = 5 - _selectedImages.length;
      if (remainingSlots <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only attach up to 5 images'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Request permissions first with proper dialog and settings navigation
      PermissionStatus status;
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use READ_MEDIA_IMAGES
        // Check if already granted
        final photosStatus = await Permission.photos.status;
        final storageStatus = await Permission.storage.status;
        
        if (photosStatus.isGranted || storageStatus.isGranted) {
          status = PermissionStatus.granted;
        } else {
          // Request photos permission first (Android 13+)
          status = await Permission.photos.request();
          
          // If photos permission is not available (older Android), try storage
          if (status.isDenied && !photosStatus.isPermanentlyDenied) {
            status = await Permission.storage.request();
          }
          
          // If permanently denied, show dialog to open settings
          if (status.isPermanentlyDenied || photosStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
            if (mounted) {
              final shouldOpenSettings = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Photo Permission Required'),
                    content: const Text(
                      'To select images for your report, please grant photo access permission. '
                      'You can enable it in the app settings.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Open Settings'),
                      ),
                    ],
                  );
                },
              );
              
              if (shouldOpenSettings == true) {
                await openAppSettings();
              }
            }
            return;
          }
          
          // If denied (not permanently), show explanation and open settings
          if (status.isDenied) {
            if (mounted) {
              final shouldOpenSettings = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Photo Permission Required'),
                    content: const Text(
                      'To select images for your report, we need access to your photos. '
                      'Please grant permission in the app settings.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Open Settings'),
                      ),
                    ],
                  );
                },
              );
              
              if (shouldOpenSettings == true) {
                await openAppSettings();
              }
            }
            return;
          }
        }
      } else {
        // For iOS
        status = await Permission.photos.request();
        
        if (status.isPermanentlyDenied) {
          if (mounted) {
            final shouldOpenSettings = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Photo Permission Required'),
                  content: const Text(
                    'To select images for your report, please grant photo access permission. '
                    'You can enable it in the app settings.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Open Settings'),
                    ),
                  ],
                );
              },
            );
            
            if (shouldOpenSettings == true) {
              await openAppSettings();
            }
          }
          return;
        }
        
        if (status.isDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission to access photos is required to select images'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      
      if (images.isNotEmpty && mounted) {
        final imagesToAdd = images.take(remainingSlots).toList();
        setState(() {
          _selectedImages.addAll(imagesToAdd);
        });
        
        if (images.length > remainingSlots && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only ${remainingSlots} image(s) added. Maximum 5 images allowed.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      debugPrint('Error in _pickImages: $e');
    }
  }

  Future<void> _removeImage(int index) async {
    if (mounted) {
      setState(() {
        _selectedImages.removeAt(index);
        if (index < _uploadedImageUrls.length) {
          _uploadedImageUrls.removeAt(index);
        }
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    List<String> imageUrls = [];

    for (var imageFile in _selectedImages) {
      try {
        // Convert image to base64
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        // For now, we'll store as data URLs. In production, you'd upload to cloud storage
        // and get URLs back. For this implementation, we'll use base64 data URLs
        final dataUrl = 'data:image/${imageFile.path.split('.').last};base64,$base64Image';
        imageUrls.add(dataUrl);
      } catch (e) {
        debugPrint('Error uploading image ${imageFile.name}: $e');
        // Continue with other images even if one fails
      }
    }

    return imageUrls;
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get user session data
      final userSession = Provider.of<UserSessionProvider>(
        context,
        listen: false,
      );

      // Get patient data
      final patient = userSession.patient;
      final clientNumber = userSession.clientNumber ?? 
          patient?['identifier'] ?? 
          patient?['patient_id']?.toString() ?? '';
      
      // Get client name - prioritize first_name and last_name
      String clientName = 'User';
      final firstName = patient?['first_name']?.toString().trim();
      final lastName = patient?['last_name']?.toString().trim();
      if (firstName != null && lastName != null && 
          firstName.isNotEmpty && lastName.isNotEmpty) {
        clientName = '$firstName $lastName';
      } else {
        clientName = userSession.getClientName() ?? 'User';
      }

      // Get phone number
      final phoneNumber = userSession.getPhoneNumber() ?? 
          patient?['phone'] ?? 
          patient?['telecom']?.toString() ?? '';

      // Validate required fields
      if (clientNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to identify your account. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Upload images first
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }

      // Prepare data for backend according to schema
      final Map<String, dynamic> reportData = {
        'client_number': clientNumber,
        'client_name': _isAnonymous ? 'Anonymous' : clientName,
        'phone_number': _isAnonymous ? null : (phoneNumber.isNotEmpty ? phoneNumber : null),
        'report_type': _selectedReportType,
        'facility_name': _facilityNameController.text.trim().isNotEmpty 
            ? _facilityNameController.text.trim() 
            : null,
        'description': _descriptionController.text.trim(),
        'is_anonymous': _isAnonymous,
        if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
      };

      // Get JWT token
      const storage = FlutterSecureStorage();
      final jwt = await storage.read(key: 'jwt');

      // Send to backend
      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/report')),
        headers: {
          'Content-Type': 'application/json',
          if (jwt != null) 'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode(reportData),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        await showSuccessBottomSheet(
          context,
          'Report Submitted Successfully',
          'Thank you for your feedback. We will review your report and take appropriate action.',
        );
        // Clear form and navigate back
        _descriptionController.clear();
        _facilityNameController.clear();
        setState(() {
          _selectedReportType = null;
          _isAnonymous = false;
          _selectedImages.clear();
          _uploadedImageUrls.clear();
        });
        Navigator.pop(context);
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorData['error'] ?? 
              errorData['details'] ?? 
              'Error submitting report. Please try again.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      debugPrint('Error submitting report: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _facilityNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: SharedAppBar(
        visitNumber: 'Report an Issue',
        onNotificationPressed: () {
          // Handle notification press
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type of Report Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedReportType,
                          decoration: InputDecoration(
                            labelText: 'Type of Report',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items:
                              _reportTypes
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedReportType = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a report type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Facility Name Field (Optional)
                        TextFormField(
                          controller: _facilityNameController,
                          decoration: InputDecoration(
                            labelText: 'Facility Name (Optional)',
                            hintText: 'Enter the name of the facility if applicable',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Describe the Issue',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText:
                                'Please provide details about the issue...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please describe the issue';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Image Upload Section
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attach Images (Optional)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can attach up to 5 images to support your report',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _selectedImages.length >= 5
                              ? null
                              : _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(
                            _selectedImages.isEmpty
                                ? 'Select Images'
                                : 'Add More Images (${_selectedImages.length}/5)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                final image = _selectedImages[index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(image.path),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.red,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            onPressed: () => _removeImage(index),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Options',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          value: _isAnonymous,
                          onChanged: (value) {
                            setState(() {
                              _isAnonymous = value ?? false;
                            });
                          },
                          title: const Text('Submit Anonymously'),
                          subtitle: const Text(
                            'Your identity will not be associated with this report',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Submit Report',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
