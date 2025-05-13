import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intimacare_client/profile.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final List<String> patientTypes = [
    'New Patient',
    'Regular Check-up',
    'Follow-up',
  ];
  final List<String> appointmentPurposes = [
    'Consultation',
    'STI/STD Testing',
    'Treatment',
    'Counseling',
    'Other',
  ];

  String? selectedPatientType;
  String? selectedPurpose;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isLoading = false;
  String notesText = '';
  String _userSex = 'female';

  // Controller for notes text field
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('patient')
            .select('sex')
            .eq('patient_id', user.id)
            .single();

        if (response != null) {
          setState(() {
            _userSex = response['sex']?.toLowerCase() ?? 'female';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<bool> _checkProfileCompletion() async {
    final supabaseClient = Supabase.instance.client;
    final user = supabaseClient.auth.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return false;
    }

    try {
      final response = await supabaseClient
          .from('patient')
          .select()
          .eq('patient_id', user.id)
          .single();

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
                  'Please complete your profile information before setting an appointment.',
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking profile: $e')));
      return false;
    }
  }

  Future<void> _saveAppointment() async {
    // Validate all required fields
    if (selectedPatientType == null ||
        selectedPurpose == null ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Check if profile is complete
    final isProfileComplete = await _checkProfileCompletion();
    if (!isProfileComplete) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Get current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a datetime object that combines date and time
      final DateTime appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // Insert appointment into database
      await Supabase.instance.client.from('appointment').insert({
        'patient_id': user.id,
        'appointment_date': appointmentDateTime.toIso8601String(),
        'type_of_patient': selectedPatientType,
        'purpose': selectedPurpose,
        'notes': notesText.isNotEmpty ? notesText : null,
      });

      // Show success dialog
      if (mounted) {
        _showAppointmentConfirmationDialog(context);
      }
    } catch (e) {
      debugPrint('Error saving appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint),
        isExpanded: true,
        underline: Container(),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    bool isWeekend(DateTime date) {
      return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    }

    final DateTime now = DateTime.now();
    DateTime firstAvailableDate =
        now.hour >= 17 ? now.add(const Duration(days: 1)) : now;

    if (isWeekend(firstAvailableDate)) {
      firstAvailableDate = firstAvailableDate.add(
        Duration(days: firstAvailableDate.weekday == DateTime.saturday ? 2 : 1),
      );
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: firstAvailableDate,
      firstDate: firstAvailableDate,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      selectableDayPredicate: (DateTime date) {
        return date.weekday != DateTime.saturday && date.weekday != DateTime.sunday;
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.red),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedTime = null;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date first')),
      );
      return;
    }

    final TimeOfDay now = TimeOfDay.now();
    const TimeOfDay clinicOpens = TimeOfDay(hour: 8, minute: 0);
    const TimeOfDay clinicCloses = TimeOfDay(hour: 17, minute: 0);

    final bool isToday = selectedDate!.day == DateTime.now().day &&
        selectedDate!.month == DateTime.now().month &&
        selectedDate!.year == DateTime.now().year;

    TimeOfDay initialTime;
    bool Function(TimeOfDay)? timeConstraint;

    if (isToday) {
      initialTime = now.hour < clinicOpens.hour
          ? clinicOpens
          : TimeOfDay(hour: now.hour + 1, minute: 0);

      timeConstraint = (TimeOfDay time) {
        return _timeToDouble(time) >= _timeToDouble(initialTime) &&
            _timeToDouble(time) < _timeToDouble(clinicCloses);
      };
    } else {
      initialTime = clinicOpens;
      timeConstraint = (TimeOfDay time) {
        return _timeToDouble(time) >= _timeToDouble(clinicOpens) &&
            _timeToDouble(time) < _timeToDouble(clinicCloses);
      };
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.red),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (timeConstraint(picked)) {
        setState(() {
          selectedTime = picked;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select a time within clinic hours (8:00 AM - 5:00 PM)'),
            ),
          );
      }
    }
  }

  double _timeToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;

  void _showAppointmentConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Appointment Set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your appointment has been successfully scheduled.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 15),
              Text('Type: $selectedPatientType'),
              Text('Purpose: $selectedPurpose'),
              Text(
                'Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
              Text('Time: ${selectedTime!.format(context)}'),
              if (notesText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Notes: $notesText'),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  selectedPatientType = null;
                  selectedPurpose = null;
                  selectedDate = null;
                  selectedTime = null;
                  notesController.clear();
                  notesText = '';
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            Icons.calendar_today,
            'Appointment',
            isSelected: true,
            onTap: () {},
          ),
          _buildNavItem(
            Icons.home,
            'Home',
            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          _buildNavItem(
            Icons.description,
            'Prescription',
            onTap: () => Navigator.pushReplacementNamed(context, '/prescription'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label, {
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.red : Colors.grey,
              size: isSelected ? 28 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.red : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        actions: [
          ProfileIconWithDropdown(userSex: _userSex),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Type of Patient'),
                  _buildDropdown(
                    value: selectedPatientType,
                    items: patientTypes,
                    hint: 'Select patient type',
                    onChanged: (value) {
                      setState(() {
                        selectedPatientType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Purpose of Appointment'),
                  _buildDropdown(
                    value: selectedPurpose,
                    items: appointmentPurposes,
                    hint: 'Select purpose',
                    onChanged: (value) {
                      setState(() {
                        selectedPurpose = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Appointment Date'),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.grey.shade600),
                          const SizedBox(width: 10),
                          Text(
                            selectedDate == null
                                ? 'Select date'
                                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                            style: TextStyle(
                              color: selectedDate == null
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Appointment Time'),
                  InkWell(
                    onTap: selectedDate == null
                        ? null
                        : () => _selectTime(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              color: Colors.grey.shade600),
                          const SizedBox(width: 10),
                          Text(
                            selectedTime == null
                                ? 'Select time'
                                : selectedTime!.format(context),
                            style: TextStyle(
                              color: selectedTime == null
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Additional Notes (Optional)'),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter any additional information...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        notesText = value;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _saveAppointment,
                      child: const Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}

class ProfileIconWithDropdown extends StatelessWidget {
  final String userSex;

  const ProfileIconWithDropdown({
    super.key,
    required this.userSex,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      icon: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(25),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/$userSex.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.person_outline,
                  size: 20,
                  color: Colors.red,
                ),
              );
            },
          ),
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/$userSex.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.red,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('My Profile'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        if (value == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        } else if (value == 'logout') {
          _showLogoutConfirmationDialog(context);
        }
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    );
                  },
                );
                try {
                  await Supabase.instance.client.auth.signOut();
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Logout',
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
  }
}