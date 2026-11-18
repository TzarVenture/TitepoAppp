import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/product.dart';
import 'custom_bag_preview_card.dart';

class CustomizeThemeBagModal extends StatefulWidget {
  final ProductModel customBagProduct;
  final Uint8List? initialImageBytes;
  final String? initialImageFileName;
  final String? initialNotes;
  final void Function(Uint8List? imageBytes, String? fileName, String notes) onSave;

  const CustomizeThemeBagModal({
    super.key,
    required this.customBagProduct,
    this.initialImageBytes,
    this.initialImageFileName,
    this.initialNotes,
    required this.onSave,
  });

  @override
  State<CustomizeThemeBagModal> createState() => _CustomizeThemeBagModalState();
}

class _CustomizeThemeBagModalState extends State<CustomizeThemeBagModal> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageFileName;
  late final TextEditingController _notesController;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.initialImageBytes;
    _imageFileName = widget.initialImageFileName;
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _isPicking = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _save() {
    if (_imageBytes == null && _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an image or provide design instructions for your custom bag.'),
          backgroundColor: AppColors.saleRed,
        ),
      );
      return;
    }

    widget.onSave(_imageBytes, _imageFileName, _notesController.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customize Your Theme Bag',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 16),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Live Interactive Bag Mockup Preview
                  CustomBagPreviewCard(
                    customImageBytes: _imageBytes,
                    customText: _notesController.text,
                    height: 220,
                  ),
                  const SizedBox(height: 10),

                  // Digital Preview Notice (from Screenshot 3)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF92400E),
                                height: 1.4,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Digital Preview Notice: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text:
                                      'This image is an instant visual mockup. Our design team will professionally format, adjust colors, and align your custom bag for perfect final printing!',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Upload Theme Image / Logo
                  Text(
                    '1. Upload Theme Image / Logo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  InkWell(
                    onTap: _isPicking ? null : _pickImage,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary,
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _isPicking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add_photo_alternate_rounded,
                                    color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _imageFileName ?? '📷 Tap to choose image (PNG, JPG, SVG)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _imageFileName != null ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _imageFileName != null
                                      ? 'Tap to replace image'
                                      : 'Birthday photo, cartoon character, logo, etc.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_imageBytes != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.saleRed, size: 20),
                              onPressed: () {
                                setState(() {
                                  _imageBytes = null;
                                  _imageFileName = null;
                                });
                              },
                              tooltip: 'Remove',
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. Design Instructions & Notes
                  Text(
                    '2. Design Instructions & Notes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    onChanged: (text) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Describe your idea here (e.g., Name, Age, Theme, or Color preferences)...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD6C5AF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD6C5AF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Base Custom Bag Price Row (from Screenshot 3)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5D7C5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Base Custom Bag Price:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          Formatters.formatPrice(widget.customBagProduct.price),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Save & Select Custom Bag Button
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.accentYellow,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save & Select Custom Bag',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
