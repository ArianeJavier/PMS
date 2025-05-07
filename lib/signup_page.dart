import 'package:flutter/material.dart';
import 'package:intimacare_client/services/supabase_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _formSubmitted = false;

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedSex;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isPasswordLongEnough = false;
  bool _hasLowerCase = false;
  bool _hasUpperCase = false;
  bool _hasNumberOrSymbol = false;
  bool _isEmailValid = false;
  bool _showPassword = false;

  final List<String> _sexOptions = ['Male', 'Female'];
  final Set<String> _touchedFields = {};

  bool _noMiddleName = false;
  String? _middleNameValidationError;

  Widget _validationIcon(bool isValid) {
    return Icon(
      isValid ? Icons.check : Icons.error_outline,
      color: isValid ? Colors.green : Colors.grey,
      size: 16,
    );
  }

  void _validatePassword(String password) {
    setState(() {
      _isPasswordLongEnough = password.length >= 8;
      _hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
      _hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
      _hasNumberOrSymbol =
          RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    });
  }

  void _validateEmail(String email) {
    setState(() {
      _isEmailValid = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
          .hasMatch(email);
    });
  }

  Future<void> _signUp() async {
    setState(() {
      _formSubmitted = true;
      _touchedFields.addAll(['firstName', 'lastName', 'email', 'password', 'sex']);
      
      if (_firstNameController.text.isEmpty) {
        _touchedFields.add('firstName');
      }
      if (_lastNameController.text.isEmpty) {
        _touchedFields.add('lastName');
      }
      if (_emailController.text.isEmpty || !_isEmailValid) {
        _touchedFields.add('email');
      }
      if (_passwordController.text.isEmpty || 
          !(_isPasswordLongEnough && _hasLowerCase && _hasUpperCase && _hasNumberOrSymbol)) {
        _touchedFields.add('password');
      }
      if (_selectedSex == null) {
        _touchedFields.add('sex');
      }
      
      if (!_noMiddleName && _middleNameController.text.isEmpty) {
        _middleNameValidationError = 'This field is required';
      } else {
        _middleNameValidationError = null;
      }
    });

    if (_middleNameValidationError != null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = {
        'first_name': _firstNameController.text.trim(),
        'middle_name': _noMiddleName ? 'N/A' : _middleNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'sex': _selectedSex,
        'username': _emailController.text.split('@')[0],
      };

      final response = await SupabaseService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userData: userData,
      );

      if (response.user != null && mounted) {
        Navigator.pushNamed(context, '/confirmation');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign up failed. Please check your information and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  bool _isFieldEmpty(String fieldName) {
    if (fieldName == 'firstName') return _firstNameController.text.isEmpty;
    if (fieldName == 'middleName') return _middleNameController.text.isEmpty;
    if (fieldName == 'lastName') return _lastNameController.text.isEmpty;
    if (fieldName == 'email') return _emailController.text.isEmpty;
    if (fieldName == 'password') return _passwordController.text.isEmpty;
    if (fieldName == 'sex') return _selectedSex == null;
    return false;
  }

  bool _isFieldInvalid(String fieldName) {
    if (fieldName == 'email') return !_isEmailValid && _emailController.text.isNotEmpty;
    if (fieldName == 'password') {
      return !(_isPasswordLongEnough && _hasLowerCase && _hasUpperCase && _hasNumberOrSymbol) && 
             _passwordController.text.isNotEmpty;
    }
    return false;
  }

  String? _getFieldError(String fieldName) {
    if (_formSubmitted || _touchedFields.contains(fieldName)) {
      if (_isFieldEmpty(fieldName)) {
        if (fieldName == 'firstName' || fieldName == 'lastName') {
          return 'This field is required';
        }
        if (fieldName == 'email') {
          return 'Please enter a valid email';
        }
        if (fieldName == 'password') {
          return 'Password must meet the required criteria';
        }
        if (fieldName == 'sex') {
          return 'Please select your sex';
        }
      }
      if (_isFieldInvalid(fieldName)) {
        if (fieldName == 'email') {
          return 'Please enter a valid email';
        }
        if (fieldName == 'password') {
          return 'Password must meet the required criteria';
        }
      }
    }
    return null;
  }

  Widget _buildTextField(
    String label,
    String hint, {
    required TextEditingController controller,
    required String fieldName,
    bool isPassword = false,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    bool showMiddleNameCheckbox = false,
  }) {
    final errorText = _getFieldError(fieldName);
    final showRequirements = (isPassword && (_formSubmitted || _touchedFields.contains(fieldName)));
    final showEmailValidation = (fieldName == 'email' && (_formSubmitted || _touchedFields.contains(fieldName)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorText != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label, style: const TextStyle(fontSize: 16)),
                const TextSpan(
                  text: ' *Required',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
          )
        else
          Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_showPassword,
          keyboardType: keyboardType,
          enabled: !showMiddleNameCheckbox || !_noMiddleName,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  )
                : null,
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12, height: 0.5),
          ),
          onChanged: (value) {
            if (isPassword) _validatePassword(value);
            if (fieldName == 'email') _validateEmail(value);
            setState(() {
              _touchedFields.add(fieldName);
              if (fieldName == 'middleName' && value.isNotEmpty) {
                _middleNameValidationError = null;
              }
            });
          },
        ),
        if (showMiddleNameCheckbox)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _noMiddleName,
                    onChanged: (bool? value) {
                      setState(() {
                        _noMiddleName = value ?? false;
                        if (_noMiddleName) {
                          _middleNameController.clear();
                          _middleNameValidationError = null;
                        } else if (_formSubmitted && _middleNameController.text.isEmpty) {
                          _middleNameValidationError = 'This field is required';
                        }
                      });
                    },
                  ),
                  const Text('I don\'t have a middle name'),
                ],
              ),
              if (_middleNameValidationError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 15.0, top: 4.0),
                  child: Text(
                    _middleNameValidationError!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        if (isPassword && showRequirements) ...[
          const SizedBox(height: 8),
          _buildPasswordRequirements(),
        ],
        if (fieldName == 'email' && showEmailValidation) ...[
          const SizedBox(height: 8),
          _buildEmailValidation(),
        ],
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    TextStyle style = const TextStyle(fontSize: 12);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('At least 8 characters long', style: style),
            _validationIcon(_isPasswordLongEnough),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('One lowercase character', style: style),
            _validationIcon(_hasLowerCase),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('One uppercase character', style: style),
            _validationIcon(_hasUpperCase),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('One number or symbol', style: style),
            _validationIcon(_hasNumberOrSymbol),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailValidation() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Valid email format (e.g., example@gmail.com)', style: const TextStyle(fontSize: 12)),
            _validationIcon(_isEmailValid),
          ],
        ),
      ],
    );
  }

  Widget _buildSexDropdown() {
    final errorText = _getFieldError('sex');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorText != null)
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Sex', style: TextStyle(fontSize: 16)),
                const TextSpan(
                  text: ' *Required',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
          )
        else
          const Text('Sex', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSex,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12, height: 0.5),
          ),
          hint: const Text('Select sex'),
          items: _sexOptions
              .map((sex) => DropdownMenuItem(value: sex, child: Text(sex)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedSex = value;
              _touchedFields.add('sex');
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: const Column(
                  children: [
                    Text(
                      'IntimaCare',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Color.fromARGB(255, 197, 0, 0),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 20),
                              color: Colors.red.shade50,
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          _buildTextField(
                            'First name',
                            'Enter first name',
                            controller: _firstNameController,
                            fieldName: 'firstName',
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            'Middle name',
                            'Enter middle name',
                            controller: _middleNameController,
                            fieldName: 'middleName',
                            isRequired: !_noMiddleName,
                            showMiddleNameCheckbox: true,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            'Last name',
                            'Enter last name',
                            controller: _lastNameController,
                            fieldName: 'lastName',
                          ),
                          const SizedBox(height: 15),
                          _buildSexDropdown(),
                          const SizedBox(height: 15),
                          _buildTextField(
                            'Email',
                            'Enter email',
                            controller: _emailController,
                            fieldName: 'email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            'Password',
                            'Enter password',
                            controller: _passwordController,
                            fieldName: 'password',
                            isPassword: true,
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
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
                                      'Sign up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: const Text(
                              "Already have an account? Sign in",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}