import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  final VoidCallback onPostCreated;

  const CreatePostScreen({
    super.key,
    required this.onPostCreated,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoadingCategories = true;

  // Controllers for common fields
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  // Dynamic values for category-specific standard structured data
  final Map<String, dynamic> _structuredData = {};

  // Location state
  Position? _currentPosition;
  bool _isLocating = false;
  String? _locationStatus;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _detectLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await ApiService().getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
          if (_categories.isNotEmpty) {
            _selectCategory(_categories.first);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  void _selectCategory(CategoryModel cat) {
    setState(() {
      _selectedCategory = cat;
      _structuredData.clear();
      // Initialize default values for dropdowns
      for (var f in cat.fieldsSchema) {
        if (f.type == 'select' && f.options.isNotEmpty) {
          _structuredData[f.id] = f.options.first;
        }
      }
    });
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _locationStatus = 'Requesting GPS permissions & coordinates...';
    });

    try {
      final pos = await LocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _isLocating = false;
          if (pos != null) {
            _locationStatus = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
            if (_cityController.text.isEmpty) {
              _cityController.text = 'Dhaka';
            }
          } else {
            _locationStatus = 'Could not access GPS. Please ensure location services are enabled.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _locationStatus = 'Location error: $e';
        });
      }
    }
  }

  static const Map<String, Map<String, String>> _categoryTemplates = {
    'tutoring': {
      'title': 'e.g. HSC & SSC Higher Math & Physics Home Tutor in Dhanmondi',
      'desc':
          'Experienced faculty member offering tailored conceptual guidance with weekly exam evaluations and mock tests.\n\n• Target Classes: Class 9 - 12 (SSC/HSC & O/A Level)\n• Subjects: Higher Mathematics, Physics, Chemistry\n• Schedule: 3 Days/week (1.5 hours per session)\n• Location: In-person home tuition or interactive online batch\n• Monthly Honorarium: Tk 8,000 - 12,000',
    },
    'teachers': {
      'title': 'e.g. Senior Lecturer in Mathematics - 10+ Years College Teaching Experience',
      'desc':
          'M.Sc in Applied Mathematics with over 10 years of institutional college teaching experience. Offering specialized advanced coaching for board exams and admissions.\n\n• Highest Degree: M.Sc in Mathematics (DU)\n• Availability: Weekend masterclasses & evening 1-on-1 mentorship\n• Rate: Tk 1,500/hour or Tk 15,000/month',
    },
    'used-products': {
      'title': 'e.g. Apple MacBook Air M2 16GB/512GB (Space Gray, Like New with Box)',
      'desc':
          'Authentic Apple MacBook Air M2 in pristine, scratchless condition with original 35W dual USB-C charger, box, and purchase memo.\n\n• Specifications: Apple M2 chip, 16GB Unified RAM, 512GB SSD\n• Battery Health: 94% (112 Cycles)\n• Warranty: Official warranty valid for 4 more months\n• Price: Tk 1,18,000 (Slightly negotiable for real buyers)\n• Pick-up Location: Gulshan 2, Dhaka',
    },
    'self-services': {
      'title': 'e.g. Professional Inverter AC Deep Jet Wash & Gas Top-Up Service',
      'desc':
          'Certified refrigeration technicians equipped with high-pressure water jet pumps, manifold gauges, and genuine refrigerant gas.\n\n• Services Included: Indoor & outdoor unit jet wash, blower cleaning, drain tray unclogging\n• Guarantee: 30-day service warranty against gas leakage\n• Inspection Fee: Tk 300 (Waived if service is taken)\n• Availability: 24/7 doorstep service across Dhaka',
    },
    'plumbing': {
      'title': 'e.g. Emergency Concealed Pipe Leakage Detection & Sanitary Repair',
      'desc':
          'Master plumber with 12+ years experience in multi-storied residential complexes and modern sanitary installations.\n\n• Specialization: Concealed acoustic leak detection, PPR pipe joint welding, geyser installation\n• Response Time: Within 45 minutes across Dhaka\n• Warranty: 90 days work guarantee on all pipe fittings',
    },
    'sell-house': {
      'title': 'e.g. 2150 Sq Ft Luxurious South Facing 3-BHK Apartment with 2 Car Parks',
      'desc':
          'Brand new ready apartment on the 6th floor with expansive south-facing cross ventilation and double balconies.\n\n• Accommodations: 3 Master Bedrooms, 4 Bathrooms, Large Drawing & Dining, Servant Suite\n• Building Amenities: Double high-speed lifts, generator backup, 24/7 CCTV & security guards\n• Land Share & Papers: Clear mutation, registered deed, Rajuk approved plan\n• Asking Price: Tk 1,85,00,000 (Negotiable)',
    },
    'sell-property': {
      'title': 'e.g. 5 Katha Prime Commercial Corner Plot Facing 60 Ft Wide Road',
      'desc':
          'High-value commercial freehold land located directly on the 60-feet wide main avenue with immense commercial potential.\n\n• Size: 5 Katha (approx. 3,600 sq ft)\n• Boundary: Demarcated RCC boundary wall with security gate\n• Utilities: Electricity line and gas supply connection available adjacent to plot\n• Documentation: CS, SA, RS, BS all Khatians updated with paid tax up to current fiscal year',
    },
    'rent-rooms': {
      'title': 'e.g. Fully Furnished Master Bedroom with Attached Bath & Balcony for Rent',
      'desc':
          'Spacious, well-ventilated master bedroom available in a modern 4th floor family apartment.\n\n• Facilities: Attached high-commode bathroom, private south balcony, ceiling fan\n• Inclusions: High-speed fiber WiFi, generator backup, filtered drinking water\n• Rent: Tk 12,000/month (Including utility and service charge)\n• Suitable For: Working executive or university student',
    },
    'rent-garage': {
      'title': 'e.g. Dedicated Covered Garage Space for Large SUV in Gated Apartment',
      'desc':
          'Secure ground floor covered parking bay suitable for large SUVs (Prado, Harrier) or sedans.\n\n• Security: 24/7 CCTV surveillance, gatekeeper guard on duty, automated sliding shutter\n• Facilities: Water hose connection for daily car washing, bright night lighting\n• Monthly Rent: Tk 4,500/month (Advance 1 month)',
    },
    'car-rental': {
      'title': 'e.g. Toyota Allion / Premio 2022 with Experienced Driver for Intercity Trips',
      'desc':
          'Premium chauffeur-driven sedan available for daily city rent, airport transfers, weddings, and outstation tours.\n\n• Vehicle Model: Toyota Allion 2022 (Pearl White, Super Cool Dual AC)\n• Chauffeur: Courteous, verified driver with 8+ years highway experience\n• Daily City Rate: Tk 3,500 (10 hours body rent, fuel & toll excluded)\n• Booking: Please confirm 24 hours prior via WhatsApp',
    },
    'homemade-food': {
      'title': 'e.g. Traditional Kacchi Biryani & Daily Diet Lunch Box Subscription',
      'desc':
          'Hygienic, mouth-watering home-cooked meals prepared with premium Basmati rice, farm-fresh mutton, and zero artificial colors.\n\n• Daily Office Lunch Box: Rice, 2 Bhortas, Thick Dal, and Chicken/Fish Curry (Tk 160/meal)\n• Weekend Specials: Mutton Kacchi Biryani with Borhani (Tk 380/platter)\n• Monthly Packages: 26-day lunch subscription with free insulated box delivery',
    },
    'matrimonial': {
      'title': 'e.g. Looking for Educated & Religious Groom for Software Engineer Bride (26)',
      'desc':
          'Respectable Suni Muslim family seeking a well-educated, gentle, and established groom for their daughter.\n\n• Bride Profile: 26 years, 5\'4", B.Sc in CSE from leading university, Senior Software Engineer\n• Looking For: 27-31 years, Minimum B.Sc / Masters, well-settled in Dhaka or abroad\n• Contact: Direct WhatsApp communication with parents',
    },
    'others': {
      'title': 'e.g. Professional Legal Documentation, Land Mutation & Registration Assistance',
      'desc':
          'Advocate and legal consultancy service helping clients with fast, hassle-free land mutation, registry vetting, and deed drafts.\n\n• Services: Land registry deed verification, Porcha/Khatian collection, municipal tax updates\n• Fees: Transparent fixed-charge per service\n• Office: Purana Paltan / Dhaka Judge Court',
    },
  };

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture location before posting')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiService().createPost(
        categoryId: _selectedCategory!.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        contactWhatsapp: _whatsappController.text.trim(),
        structuredData: _structuredData,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _addressController.text.trim(),
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : 'Dhaka',
      );

      if (mounted) {
        // Clear all fields on success
        _titleController.clear();
        _descController.clear();
        _whatsappController.clear();
        _addressController.clear();
        _structuredData.clear();
        _formKey.currentState?.reset();

        if (_selectedCategory != null) {
          _selectCategory(_selectedCategory!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.whatsAppGreen,
            content: Text('SignBoard post published successfully! Fields cleared.'),
          ),
        );
        widget.onPostCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.dangerRed,
            content: Text('Publish error: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        title: const Text(
          'Create SignBoard Post',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryDark,
          ),
        ),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Step 1: Select Category
                  _buildSectionHeader('1. Select Standard Category'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<CategoryModel>(
                        value: _selectedCategory,
                        isExpanded: true,
                        hint: const Text('Choose category'),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<CategoryModel>(
                            value: cat,
                            child: Row(
                              children: [
                                const Icon(Icons.label_outline, size: 18, color: AppTheme.primaryDark),
                                const SizedBox(width: 10),
                                Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (cat) {
                          if (cat != null) _selectCategory(cat);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Step 2: Category Specific Standard Fields
                  if (_selectedCategory != null &&
                      _selectedCategory!.fieldsSchema.isNotEmpty) ...[
                    _buildSectionHeader(
                      '2. Standard ${_selectedCategory!.name} Parameters',
                      subtitle: 'Structured details specific to this category',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _selectedCategory!.fieldsSchema.map((field) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildDynamicField(field),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Step 3: Contact & Overview Information
                  _buildSectionHeader('3. Overview & Contact Information'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          'Title *',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleController,
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Title is required' : null,
                          decoration: InputDecoration(
                            hintText: _categoryTemplates[_selectedCategory?.id]?['title'] ??
                                'e.g. Detailed Listing Title',
                            helperText: 'A concise summary matching this category',
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Description *',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                final tmpl = _categoryTemplates[_selectedCategory?.id]?['desc'];
                                if (tmpl != null) {
                                  setState(() {
                                    _descController.text = tmpl;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy_rounded, size: 15, color: AppTheme.accentBlue),
                                    SizedBox(width: 4),
                                    Text(
                                      'Use Template',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.accentBlue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descController,
                          minLines: 6,
                          maxLines: 12,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: _categoryTemplates[_selectedCategory?.id]?['desc'] ??
                                'Provide complete details and terms...',
                            alignLabelWithHint: true,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Helpful category example card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderLight, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline_rounded,
                                      size: 18, color: AppTheme.accentBlue),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Example Template (${_selectedCategory?.name ?? "General"}):',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _categoryTemplates[_selectedCategory?.id]?['desc'] ??
                                    'Clear specifications, pricing, schedule, and warranty...',
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // WhatsApp Number (Important for direct card action)
                        const Text(
                          'WhatsApp Phone Number *',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'WhatsApp number is required';
                            }
                            final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                            if (digits.length < 8) {
                              return 'Enter a valid phone number with country code';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: '+12345678901 or +8801700000000',
                            prefixIcon: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: AppTheme.whatsAppGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Step 4: GPS Geolocation Permission & Coordinates
                  _buildSectionHeader(
                    '4. Geolocation & Map Route Data',
                    subtitle: 'Allows users to calculate minimum distance & navigate to your location',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _currentPosition != null
                                    ? const Color(0xFFDCFCE7)
                                    : AppTheme.goRouteBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.my_location_rounded,
                                color: _currentPosition != null
                                    ? AppTheme.whatsAppGreen
                                    : AppTheme.primaryDark,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentPosition != null
                                        ? 'GPS Coordinates Saved'
                                        : 'GPS Permission Pending',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                  Text(
                                    _locationStatus ?? 'Ready to fetch GPS',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _isLocating ? null : _detectLocation,
                              icon: _isLocating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh, size: 20),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Address / Landmark
                        const Text(
                          'Street / Area Name',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Road 11, Block D, Banani',
                          ),
                        ),

                        const SizedBox(height: 12),

                        // City
                        const Text(
                          'City',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Dhaka',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Publish SignBoard Post',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryDark,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDynamicField(CategoryFieldSchema field) {
    if (field.type == 'select') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label + (field.required ? ' *' : ''),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.bgCanvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _structuredData[field.id] ??
                    (field.options.isNotEmpty ? field.options.first : null),
                isExpanded: true,
                items: field.options.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt,
                    child: Text(opt, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _structuredData[field.id] = val;
                  });
                },
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label + (field.required ? ' *' : ''),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          keyboardType: field.type == 'number'
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          validator: (val) {
            if (field.required && (val == null || val.trim().isEmpty)) {
              return '${field.label} is required';
            }
            return null;
          },
          onChanged: (val) {
            _structuredData[field.id] = val;
          },
          decoration: InputDecoration(
            hintText: field.placeholder.isNotEmpty
                ? field.placeholder
                : 'Enter ${field.label.toLowerCase()}',
          ),
        ),
      ],
    );
  }
}
