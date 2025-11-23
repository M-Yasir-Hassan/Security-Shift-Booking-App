import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/shift.dart';
import '../../services/shift_service.dart';
import '../../services/auth_service.dart';

class CreateShiftScreen extends StatefulWidget {
  const CreateShiftScreen({super.key});

  @override
  State<CreateShiftScreen> createState() => _CreateShiftScreenState();
}

class _CreateShiftScreenState extends State<CreateShiftScreen> {
  final _formKey = GlobalKey<FormState>();
  final ShiftService _shiftService = ShiftService.instance;
  final AuthService _authService = AuthService.instance;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _guardsNeededController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  
  // Form state
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 9));
  ShiftType _selectedShiftType = ShiftType.stewardShift;
  bool _isUrgent = false;
  bool _isLoading = false;
  List<String> _selectedCertifications = [];
  
  // Available certifications
  final List<String> _availableCertifications = [
    'Security License',
    'First Aid',
    'CPR',
    'Fire Safety',
    'Crowd Control',
    'Armed Security',
    'CCTV Operation',
    'Access Control',
    'Emergency Response',
    'Customer Service',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _hourlyRateController.dispose();
    _guardsNeededController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartTime ? _startTime : _endTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartTime) {
            _startTime = newDateTime;
            // Ensure end time is after start time
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 8));
            }
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _createShift() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final shift = Shift(
        id: 'shift_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        locationId: 'loc_${DateTime.now().millisecondsSinceEpoch}',
        locationName: _locationController.text.trim(),
        locationAddress: _addressController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        hourlyRate: double.parse(_hourlyRateController.text),
        requiredGuards: int.parse(_guardsNeededController.text),
        assignedGuards: 0,
        status: ShiftStatus.open,
        shiftType: _selectedShiftType,
        createdBy: currentUser.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        requiredCertifications: _selectedCertifications,
        specialInstructions: _specialInstructionsController.text.trim().isEmpty 
            ? null 
            : _specialInstructionsController.text.trim(),
        uniformRequirements: 'Black formal trousers, white shirt, black tie, black formal shoes, black jacket',
        isUrgent: _isUrgent,
        assignments: [],
      );

      final result = await _shiftService.createShift(shift);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shift created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to create shift'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Shift'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionCard(
                'Basic Information',
                [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Shift Title',
                    hint: 'e.g., Night Security at Mall',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a shift title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Describe the shift responsibilities...',
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Shift Type',
                    value: _selectedShiftType,
                    items: ShiftType.values.map((type) => 
                      DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      ),
                    ).toList(),
                    onChanged: (value) {
                      setState(() => _selectedShiftType = value!);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Location Information
              _buildSectionCard(
                'Location',
                [
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location Name',
                    hint: 'e.g., Downtown Shopping Mall',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a location name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Full Address',
                    hint: 'Street address, city, state, zip',
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the full address';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Schedule
              _buildSectionCard(
                'Schedule',
                [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeField(
                          label: 'Start Time',
                          dateTime: _startTime,
                          onTap: () => _selectDateTime(context, true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateTimeField(
                          label: 'End Time',
                          dateTime: _endTime,
                          onTap: () => _selectDateTime(context, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Duration: ${_endTime.difference(_startTime).inHours}h ${_endTime.difference(_startTime).inMinutes % 60}m',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Payment & Staffing
              _buildSectionCard(
                'Payment & Staffing',
                [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _hourlyRateController,
                          label: 'Hourly Rate (\$)',
                          hint: '25.00',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter hourly rate';
                            }
                            final rate = double.tryParse(value);
                            if (rate == null || rate <= 0) {
                              return 'Please enter a valid rate';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _guardsNeededController,
                          label: 'Guards Needed',
                          hint: '2',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter number of guards';
                            }
                            final guards = int.tryParse(value);
                            if (guards == null || guards <= 0) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_hourlyRateController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Total Pay: \$${(double.tryParse(_hourlyRateController.text) ?? 0) * _endTime.difference(_startTime).inHours}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // Requirements
              _buildSectionCard(
                'Requirements',
                [
                  const Text(
                    'Required Certifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableCertifications.map((cert) {
                      final isSelected = _selectedCertifications.contains(cert);
                      return FilterChip(
                        label: Text(cert),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCertifications.add(cert);
                            } else {
                              _selectedCertifications.remove(cert);
                            }
                          });
                        },
                        selectedColor: const Color(0xFF1565C0).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF1565C0),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Additional Options
              _buildSectionCard(
                'Additional Options',
                [
                  SwitchListTile(
                    title: const Text('Urgent Shift'),
                    subtitle: const Text('Mark this as an urgent shift'),
                    value: _isUrgent,
                    onChanged: (value) {
                      setState(() => _isUrgent = value);
                    },
                    activeColor: const Color(0xFF1565C0),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _specialInstructionsController,
                    label: 'Special Instructions (Optional)',
                    hint: 'Any special requirements or instructions...',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createShift,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Shift',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime dateTime,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(dateTime),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}\n${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Extension removed as ShiftType enum already has displayName property
