import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_bloc.dart';
import '../../../core/auth/models/auth_event.dart';
import '../../../core/auth/models/auth_state.dart';
import '../../../core/auth/models/user_model.dart';
import '../../../shared/widgets/afri_button.dart';

class CountryCurrencyInfo {
  final String name;
  final String code;
  final String symbol;
  final String flag;

  const CountryCurrencyInfo({
    required this.name,
    required this.code,
    required this.symbol,
    required this.flag,
  });
}

class ToolOnboardingWizard extends StatefulWidget {
  final String targetToolTitle;
  final VoidCallback onComplete;

  const ToolOnboardingWizard({
    super.key,
    required this.targetToolTitle,
    required this.onComplete,
  });

  @override
  State<ToolOnboardingWizard> createState() => _ToolOnboardingWizardState();
}

class _ToolOnboardingWizardState extends State<ToolOnboardingWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Step 1: Personal Details
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Step 2: Occupation Choice
  String _selectedOccupation = 'Farmer'; // Farmer, Student, Guest, Researcher, Commercial Manager

  // Step 3: Location & Country-Specific Currency
  static const List<CountryCurrencyInfo> _countries = [
    CountryCurrencyInfo(name: 'South Africa', code: 'ZAR', symbol: 'R', flag: '🇿🇦'),
    CountryCurrencyInfo(name: 'Kenya', code: 'KES', symbol: 'KSh', flag: '🇰🇪'),
    CountryCurrencyInfo(name: 'Nigeria', code: 'NGN', symbol: '₦', flag: '🇳🇬'),
    CountryCurrencyInfo(name: 'Botswana', code: 'BWP', symbol: 'P', flag: '🇧🇼'),
    CountryCurrencyInfo(name: 'Namibia', code: 'NAD', symbol: 'N\$', flag: '🇳🇦'),
    CountryCurrencyInfo(name: 'Zimbabwe', code: 'ZWG', symbol: 'ZiG', flag: '🇿🇼'),
    CountryCurrencyInfo(name: 'Ghana', code: 'GHS', symbol: 'GH₵', flag: '🇬🇭'),
    CountryCurrencyInfo(name: 'United States / International', code: 'USD', symbol: '\$', flag: '🌍'),
  ];
  late CountryCurrencyInfo _selectedCountry;
  final _cityController = TextEditingController();

  // Step 4: Customized Rangeland & Preference Options
  String _farmSizeRange = '50 - 500 ha';
  final List<String> _selectedLivestock = ['Cattle'];
  String _primaryGoal = 'Optimize Rotational Grazing & Vegetation';

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries.first;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      if (user.fullName != null && user.fullName!.isNotEmpty) {
        final parts = user.fullName!.split(' ');
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
      if (user.firstName != null) _firstNameController.text = user.firstName!;
      if (user.lastName != null) _lastNameController.text = user.lastName!;
      if (user.city != null) _cityController.text = user.city!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final currentUser = authState.user;

      double farmSize = 250;
      if (_farmSizeRange.contains('<50')) farmSize = 30;
      if (_farmSizeRange.contains('500 - 2000')) farmSize = 1200;
      if (_farmSizeRange.contains('2000+')) farmSize = 3500;

      final updatedUser = currentUser.copyWith(
        firstName: _firstNameController.text.trim().isEmpty ? 'Farmer' : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        fullName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
        occupation: _selectedOccupation.toLowerCase(),
        country: _selectedCountry.name,
        currency: _selectedCountry.code,
        currencySymbol: _selectedCountry.symbol,
        city: _cityController.text.trim(),
        farmSizeHectares: farmSize,
        primaryLivestock: _selectedLivestock.join(', '),
        primaryGoal: _primaryGoal,
        hasCompletedOnboarding: true,
      );

      context.read<AuthBloc>().add(UpdateProfileEvent(updatedUser));
    }
    
    Navigator.of(context).pop();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Setup for ${widget.targetToolTitle}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: primaryColor.withOpacity(0.06),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${((_currentStep + 1) / _totalSteps * 100).round()}% Completed',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),

            // Onboarding Step Views
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildStep1PersonalDetails(),
                  _buildStep2OccupationChoice(),
                  _buildStep3LocationAndCurrency(),
                  _buildStep4CustomizationPreferences(),
                ],
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AfriButton(
                      label: _currentStep == _totalSteps - 1
                          ? 'LAUNCH TOOL'
                          : 'NEXT STEP',
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Personal Details ---
  Widget _buildStep1PersonalDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_pin, size: 48, color: Color(0xFF2E7D32)),
          const SizedBox(height: 12),
          const Text(
            'Welcome! Let\'s introduce yourself',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'To personalize your experience for ${widget.targetToolTitle}, please tell us your name.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name *',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Surname / Last Name',
              prefixIcon: const Icon(Icons.family_restroom_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Occupation Choice ---
  Widget _buildStep2OccupationChoice() {
    final occupations = [
      {
        'title': 'Farmer / Rancher',
        'val': 'Farmer',
        'desc': 'I manage livestock, paddocks, or communal grazing lands.',
        'icon': Icons.agriculture,
      },
      {
        'title': 'Student / Researcher',
        'val': 'Student',
        'desc': 'I study agriculture, rangeland ecology, or botanical science.',
        'icon': Icons.school,
      },
      {
        'title': 'Guest / Consultant',
        'val': 'Guest',
        'desc': 'I am exploring AfriRange AI capabilities or consulting.',
        'icon': Icons.explore,
      },
      {
        'title': 'Commercial Manager',
        'val': 'Commercial Manager',
        'desc': 'I manage large-scale livestock operations or corporate farms.',
        'icon': Icons.domain,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.work_outline, size: 48, color: Color(0xFF1565C0)),
          const SizedBox(height: 12),
          const Text(
            'What best describes your role?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'We tailor intelligence algorithms & tools based on your daily workflow.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          ...occupations.map((item) {
            final isSelected = _selectedOccupation == item['val'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedOccupation = item['val'] as String;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1,
                    ),
                    color: isSelected ? const Color(0xFF2E7D32).withOpacity(0.05) : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 32,
                        color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['desc'] as String,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: item['val'] as String,
                        groupValue: _selectedOccupation,
                        activeColor: const Color(0xFF2E7D32),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedOccupation = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Step 3: Location & Currency ---
  Widget _buildStep3LocationAndCurrency() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.public, size: 48, color: Color(0xFFEF6C00)),
          const SizedBox(height: 12),
          const Text(
            'Where are you located?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'We use your location to customize weather satellite feeds & set your local currency display.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),

          // Country Select
          const Text('Country & Local Currency *', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<CountryCurrencyInfo>(
            value: _selectedCountry,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.map_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: _countries.map((c) {
              return DropdownMenuItem<CountryCurrencyInfo>(
                value: c,
                child: Row(
                  children: [
                    Text(c.flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text('${c.name} (${c.code} - ${c.symbol})'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedCountry = val;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          // City Input
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'City / Region (Optional)',
              prefixIcon: const Icon(Icons.location_city),
              hintText: 'e.g. Kimberley, Eldoret, Kano, Gaborone',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 20),

          // Currency Preview Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, color: Colors.amber, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Currency Customization Active',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'All subscription tiers and AI credit pricing will be displayed in ${_selectedCountry.code} (${_selectedCountry.symbol}).',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 4: Customization Preferences ---
  Widget _buildStep4CustomizationPreferences() {
    final isFarmer = _selectedOccupation == 'Farmer' || _selectedOccupation == 'Commercial Manager';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tune, size: 48, color: Color(0xFF6A1B9A)),
          const SizedBox(height: 12),
          const Text(
            'Tailor Your Intelligence',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Select your preferences to customize dashboard analytics and recommendations.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),

          if (isFarmer) ...[
            const Text('Farm / Range Size', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['<50 ha', '50 - 500 ha', '500 - 2000 ha', '2000+ ha'].map((size) {
                final selected = _farmSizeRange == size;
                return ChoiceChip(
                  label: Text(size),
                  selected: selected,
                  selectedColor: const Color(0xFF2E7D32),
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                  onSelected: (val) {
                    if (val) setState(() => _farmSizeRange = size);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text('Primary Livestock (Select all that apply)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Cattle', 'Sheep', 'Goats', 'Game/Wildlife', 'Poultry'].map((stock) {
                final selected = _selectedLivestock.contains(stock);
                return FilterChip(
                  label: Text(stock),
                  selected: selected,
                  selectedColor: const Color(0xFF2E7D32),
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedLivestock.add(stock);
                      } else {
                        if (_selectedLivestock.length > 1) {
                          _selectedLivestock.remove(stock);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          const Text('Main Goal / Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _primaryGoal,
            decoration: OutlineInputBorder(borderRadius: BorderRadius.circular(10)).buildDecorationMap({}),
            items: const [
              DropdownMenuItem(
                value: 'Optimize Rotational Grazing & Vegetation',
                child: Text('Optimize Rotational Grazing & Vegetation'),
              ),
              DropdownMenuItem(
                value: 'Early Drought Warning & Water Security',
                child: Text('Early Drought Warning & Water Security'),
              ),
              DropdownMenuItem(
                value: 'Plant Identification & Toxic Weed Removal',
                child: Text('Plant Identification & Toxic Weed Removal'),
              ),
              DropdownMenuItem(
                value: 'Livestock Health & Stocking Rate Calculator',
                child: Text('Livestock Health & Stocking Rate Calculator'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _primaryGoal = val);
            },
          ),
        ],
      ),
    );
  }
}

extension OutlineInputBorderX on OutlineInputBorder {
  InputDecoration buildDecorationMap(Map<String, String> m) {
    return InputDecoration(
      prefixIcon: const Icon(Icons.flag),
      border: this,
    );
  }
}
