import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/customer_address.dart';
import '../../services/storage_service.dart';

class CustomerAddressesScreen extends StatefulWidget {
  const CustomerAddressesScreen({super.key});

  @override
  State<CustomerAddressesScreen> createState() => _CustomerAddressesScreenState();
}

class _CustomerAddressesScreenState extends State<CustomerAddressesScreen> {
  List<CustomerAddress> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final rawList = await StorageService.loadAddresses();
    if (rawList.isEmpty) {
      // Provide default sample address for quick start
      final defaultAddr = [
        const CustomerAddress(
          id: 'addr_default_1',
          name: 'Pooja Sharma',
          phone: '9876543210',
          pincode: '560038',
          flatHouse: 'Flat 402, Sunshine Heights',
          areaStreet: '12th Main, HAL 2nd Stage, Indiranagar',
          landmark: 'Opp. Sony Center',
          city: 'Bengaluru',
          state: 'Karnataka',
          type: 'Home',
          isDefault: true,
        ),
      ];
      _addresses = defaultAddr;
      await _persistAddresses();
    } else {
      _addresses = rawList.map((str) {
        try {
          return CustomerAddress.fromJson(jsonDecode(str));
        } catch (_) {
          return null;
        }
      }).whereType<CustomerAddress>().toList();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _persistAddresses() async {
    final rawList = _addresses.map((a) => jsonEncode(a.toJson())).toList();
    await StorageService.saveAddresses(rawList);
  }

  void _setDefault(CustomerAddress target) {
    setState(() {
      _addresses = _addresses.map((addr) {
        return addr.copyWith(isDefault: addr.id == target.id);
      }).toList();
    });
    _persistAddresses();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Default delivery address set to ${target.type}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteAddress(CustomerAddress target) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Address?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove this ${target.type} address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _addresses.removeWhere((a) => a.id == target.id);
                if (target.isDefault && _addresses.isNotEmpty) {
                  _addresses[0] = _addresses[0].copyWith(isDefault: true);
                }
              });
              _persistAddresses();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address deleted.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openAddressForm({CustomerAddress? existingAddress}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressFormSheet(
        existingAddress: existingAddress,
        onSave: (savedAddress) {
          setState(() {
            if (existingAddress != null) {
              final index = _addresses.indexWhere((a) => a.id == existingAddress.id);
              if (index != -1) {
                _addresses[index] = savedAddress;
              }
            } else {
              if (savedAddress.isDefault) {
                _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
              }
              _addresses.add(savedAddress);
            }

            // Ensure at least one default
            if (!_addresses.any((a) => a.isDefault) && _addresses.isNotEmpty) {
              _addresses[0] = _addresses[0].copyWith(isDefault: true);
            }
          });
          _persistAddresses();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Saved Addresses',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _openAddressForm(),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: Text(
              'Add New Delivery Address',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off_rounded, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'No Addresses Saved Yet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add your delivery addresses for seamless 1-tap checkout.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: address.isDefault ? AppColors.primary : AppColors.borderLight,
                          width: address.isDefault ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: address.isDefault
                                          ? AppColors.primary.withValues(alpha: 0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      address.type.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: address.isDefault ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  if (address.isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'DEFAULT',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _openAddressForm(existingAddress: address);
                                  } else if (val == 'delete') {
                                    _deleteAddress(address);
                                  } else if (val == 'default') {
                                    _setDefault(address);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  if (!address.isDefault)
                                    const PopupMenuItem(
                                      value: 'default',
                                      child: Text('Set as Default'),
                                    ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit Address'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Address', style: TextStyle(color: AppColors.error)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            address.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address.fullAddress,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                '+91 ${address.phone}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (!address.isDefault) ...[
                            const Divider(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _setDefault(address),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Set as Default',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final CustomerAddress? existingAddress;
  final ValueChanged<CustomerAddress> onSave;

  const _AddressFormSheet({
    this.existingAddress,
    required this.onSave,
  });

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _flatController;
  late final TextEditingController _streetController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;

  late String _selectedType;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAddress;
    _nameController = TextEditingController(text: a?.name ?? '');
    _phoneController = TextEditingController(text: a?.phone ?? '');
    _pincodeController = TextEditingController(text: a?.pincode ?? '');
    _flatController = TextEditingController(text: a?.flatHouse ?? '');
    _streetController = TextEditingController(text: a?.areaStreet ?? '');
    _landmarkController = TextEditingController(text: a?.landmark ?? '');
    _cityController = TextEditingController(text: a?.city ?? '');
    _stateController = TextEditingController(text: a?.state ?? '');
    _selectedType = a?.type ?? 'Home';
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _flatController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final result = CustomerAddress(
      id: widget.existingAddress?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      pincode: _pincodeController.text.trim(),
      flatHouse: _flatController.text.trim(),
      areaStreet: _streetController.text.trim(),
      landmark: _landmarkController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      type: _selectedType,
      isDefault: _isDefault,
    );

    widget.onSave(result);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingAddress != null ? 'Edit Address' : 'Add New Address',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Full Name & Phone
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Name *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '10-Digit Mobile *',
                        prefixText: '+91 ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length != 10) {
                          return 'Enter 10 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Pincode & City & State
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pincode (6 digits) *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) => val == null || val.trim().length != 6 ? '6 digits' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Flat, House no.
              TextFormField(
                controller: _flatController,
                decoration: const InputDecoration(
                  labelText: 'Flat, House No., Building Name *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Area, Street
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Road Name, Area, Colony *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Landmark
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  labelText: 'Nearby Landmark (Optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),

              // Address Type Chips
              Text(
                'Address Type',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['Home', 'Work', 'Other'].map((type) {
                  final isSel = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedType = type;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 10),

              // Checkbox: Set Default
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Make this my default address',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                value: _isDefault,
                onChanged: (val) {
                  setState(() {
                    _isDefault = val ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  widget.existingAddress != null ? 'Update Address' : 'Save Address',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
