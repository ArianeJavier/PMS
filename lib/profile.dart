import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseClient = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic> _patientData = {};
  final Map<String, dynamic> _updatedData = {};
  final TextEditingController _birthdayController = TextEditingController();

  // Civil status options
  final List<String> _civilStatusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Separated',
    'Prefer not to say',
  ];

  // Track which fields have been filled to hide "*Required"
  final Map<String, bool> _fieldFilledStatus = {
    'birthday': false,
    'place_of_birth': false,
    'contact_number': false,
    'civil_status': false,
    'house_number': false,
    'street': false,
    'barangay': false,
    'city': false,
    'province': false,
    'zip_code': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  @override
  void dispose() {
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        final response =
            await _supabaseClient.from('patient').select().eq('patient_id', user.id).single();

        if (response != null) {
          setState(() {
            _patientData = response;
            if (_patientData['birthday'] != null) {
              _birthdayController.text = _patientData['birthday'];
              _fieldFilledStatus['birthday'] = true;
            }
            
            // Update filled status for all fields
            _fieldFilledStatus.forEach((key, _) {
              if (_patientData[key] != null && _patientData[key].toString().isNotEmpty) {
                _fieldFilledStatus[key] = true;
              }
            });
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        await _supabaseClient.from('patient').update(_updatedData).eq('patient_id', user.id);
        
        // Refresh the data after update
        await _loadPatientData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.red),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _updatedData['birthday'] = _birthdayController.text;
        _fieldFilledStatus['birthday'] = true;
      });
    }
  }

  Widget _buildLabel(String label, String fieldKey, bool isRequired) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        if (isRequired && !_fieldFilledStatus[fieldKey]!)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              '*Required',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      _buildProfileImage(),
                      _buildPersonalInfoForm(),
                      _buildContactInfoForm(),
                      _buildAddressInfoForm(),
                      const SizedBox(height: 20),
                      _buildSaveButton(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 2),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.arrow_back, color: Colors.red, size: 20),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IntimaCare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color.fromARGB(255, 197, 0, 0),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/${_patientData['sex'] ?? 'female'}.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // First Name (read-only)
          _buildTextField(
            'First Name',
            fieldKey: 'first_name',
            initialValue: _patientData['first_name'] ?? '',
            readOnly: true,
          ),

          // Middle Name (read-only)
          _buildTextField(
            'Middle Name',
            fieldKey: 'middle_name',
            initialValue: _patientData['middle_name'] ?? '',
            readOnly: true,
          ),

          // Last Name (read-only)
          _buildTextField(
            'Last Name',
            fieldKey: 'last_name',
            initialValue: _patientData['last_name'] ?? '',
            readOnly: true,
          ),

          // Suffix
          _buildTextField(
            'Suffix',
            fieldKey: 'suffix',
            initialValue: _patientData['suffix'] ?? '',
            onSaved: (value) {
              if (value != null && value.isNotEmpty) {
                _updatedData['suffix'] = value;
              }
            },
          ),

          // Sex (read-only)
          _buildTextField(
            'Sex',
            fieldKey: 'sex',
            initialValue: _patientData['sex']?.toString().toUpperCase() ?? '',
            readOnly: true,
          ),

          // Birthday
          InkWell(
            onTap: _selectDate,
            child: IgnorePointer(
              child: _buildTextField(
                'Birthday',
                fieldKey: 'birthday',
                controller: _birthdayController,
                isDate: true,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your birthday';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _fieldFilledStatus['birthday'] = value?.isNotEmpty ?? false;
                  });
                },
              ),
            ),
          ),

          // Place of Birth
          _buildTextField(
            'Place of Birth',
            fieldKey: 'place_of_birth',
            initialValue: _patientData['place_of_birth'] ?? '',
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your place of birth';
              }
              return null;
            },
            onSaved: (value) {
              if (value != null && value.isNotEmpty) {
                _updatedData['place_of_birth'] = value;
              }
            },
            onChanged: (value) {
              setState(() {
                _fieldFilledStatus['place_of_birth'] = value?.isNotEmpty ?? false;
              });
            },
          ),

          // Civil Status Dropdown
          _buildDropdownField(
            'Civil Status',
            fieldKey: 'civil_status',
            value: _patientData['civil_status'],
            items: _civilStatusOptions,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your civil status';
              }
              return null;
            },
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _updatedData['civil_status'] = newValue;
                  _fieldFilledStatus['civil_status'] = true;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Contact Number
          _buildTextField(
            'Contact Number',
            fieldKey: 'contact_number',
            initialValue: _patientData['contact_number'] ?? '',
            isRequired: true,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your contact number';
              }
              return null;
            },
            onSaved: (value) {
              if (value != null && value.isNotEmpty) {
                _updatedData['contact_number'] = value;
              }
            },
            onChanged: (value) {
              setState(() {
                _fieldFilledStatus['contact_number'] = value?.isNotEmpty ?? false;
              });
            },
          ),

          // Email (read-only)
          _buildTextField(
            'Email',
            fieldKey: 'email',
            initialValue: _patientData['email'] ?? '',
            readOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInfoForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Address Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // House Number
          _buildTextField(
            'House Number',
            fieldKey: 'house_number',
            initialValue: _patientData['house_number'] ?? '',
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your house number';
              }
              return null;
            },
            onSaved: (value) {
              if (value != null && value.isNotEmpty) {
                _updatedData['house_number'] = value;
              }
            },
            onChanged: (value) {
              setState(() {
                _fieldFilledStatus['house_number'] = value?.isNotEmpty ?? false;
              });
            },
          ),

          // Street
          _buildTextField(
            'Street',
            fieldKey: 'street',
            initialValue: _patientData['street'] ?? '',
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your street';
              }
              return null;
            },
            onSaved: (value) {
              if (value != null && value.isNotEmpty) {
                _updatedData['street'] = value;
              }
            },
            onChanged: (value) {
              setState(() {
                _fieldFilledStatus['street'] = value?.isNotEmpty ?? false;
              });
            },
          ),

          // Barangay
          _buildTextField(
            'Barangay',
            fieldKey: 'barangay',
            initialValue: _patientData['barangay'] ?? '',
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your barangay';
              }
              return null;
            },
            onSaved: (value) {
              if (value != null && value.isNotEmpty) {
                _updatedData['barangay'] = value;
              }
            },
            onChanged: (value) {
              setState(() {
                _fieldFilledStatus['barangay'] = value?.isNotEmpty ?? false;
              });
            },
          ),

          // City
          _buildTextField(
            'City',
            fieldKey: 'city',
            initialValue: _patientData['city'] ?? '',
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your city';
              }
              return null;
            },
            onSaved: (value) {
              if (value != null && value.isNotEmpty) {
                _updatedData['city'] = value;
              }
            },
            onChanged: (value) {
              setState(() {
                _fieldFilledStatus['city'] = value?.isNotEmpty ?? false;
              });
            },
          ),

          // Province
          _buildTextField(
            'Province',
            fieldKey: 'province',
            initialValue: _patientData['province'] ?? '',
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your province';
              }
              return null;
            },
            onSaved: (value) {
              if (value != null && value.isNotEmpty) {
                _updatedData['province'] = value;
              }
            },
            onChanged: (value) {
              setState(() {
                _fieldFilledStatus['province'] = value?.isNotEmpty ?? false;
              });
            },
          ),

          // Zip Code
          _buildTextField(
            'Zip Code',
            fieldKey: 'zip_code',
            initialValue: _patientData['zip_code'] ?? '',
            isRequired: true,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your zip code';
              }
              return null;
            },
            onSaved: (value) {
              if (value != null && value.isNotEmpty) {
                _updatedData['zip_code'] = value;
              }
            },
            onChanged: (value) {
              setState(() {
                _fieldFilledStatus['zip_code'] = value?.isNotEmpty ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required String fieldKey,
    String? initialValue,
    TextEditingController? controller,
    bool readOnly = false,
    bool isDate = false,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label, fieldKey, isRequired),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            initialValue: initialValue,
            readOnly: readOnly || isDate,
            keyboardType: keyboardType,
            validator: validator,
            onSaved: onSaved,
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: isDate
                  ? const Icon(Icons.calendar_today, color: Colors.grey)
                  : null,
              errorStyle: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label, {
    required String fieldKey,
    String? value,
    required List<String> items,
    bool isRequired = false,
    String? Function(String?)? validator,
    void Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label, fieldKey, isRequired),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              validator: validator,
              onChanged: onChanged,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                errorStyle: const TextStyle(color: Colors.red),
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              dropdownColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

Future<bool> checkProfileCompletion(BuildContext context) async {
  final supabaseClient = Supabase.instance.client;
  final user = supabaseClient.auth.currentUser;

  if (user == null) {
    Navigator.pushReplacementNamed(context, '/login');
    return false;
  }

  try {
    final response = await supabaseClient.from('patient').select().eq('patient_id', user.id).single();

    if (response == null) {
      return false;
    }

    final requiredFields = [
      'birthday',
      'place_of_birth',
      'house_number',
      'street',
      'barangay',
      'city',
      'province',
      'zip_code',
      'contact_number',
      'civil_status',
    ];

    for (var field in requiredFields) {
      if (response[field] == null || response[field].toString().isEmpty) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Complete Your Profile'),
              content: const Text(
                'Please complete your profile information before proceeding.',
              ),
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Complete Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            );
          },
        );
        return false;
      }
    }
    return true;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error checking profile: $e')));
    return false;
  }
}