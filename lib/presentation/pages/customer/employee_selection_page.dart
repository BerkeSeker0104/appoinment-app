import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../data/models/company_user_model.dart';
import '../../../../data/models/branch_model.dart';
import '../../../../data/services/company_user_api_service.dart';
import 'service_selection_page.dart';

class EmployeeSelectionPage extends StatefulWidget {
  final String barberId;
  final String barberName;
  final String barberImage;
  final BranchModel? branch;

  const EmployeeSelectionPage({
    super.key,
    required this.barberId,
    required this.barberName,
    required this.barberImage,
    this.branch,
  });

  @override
  State<EmployeeSelectionPage> createState() => _EmployeeSelectionPageState();
}

class _EmployeeSelectionPageState extends State<EmployeeSelectionPage> {
  final CompanyUserApiService _companyUserService = CompanyUserApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<CompanyUserModel> _employees = [];
  List<CompanyUserModel> _filteredEmployees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filterEmployees();
    });
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredEmployees = List.from(_employees);
    } else {
      _filteredEmployees = _employees.where((employee) {
        final fullName = '${employee.userDetail.name} ${employee.userDetail.surname}'.toLowerCase();
        return fullName.contains(query);
      }).toList();
    }
  }

  Future<void> _loadEmployees() async {
    try {
      setState(() => _isLoading = true);
      final employees = await _companyUserService.getCompanyEmployees(widget.barberId);
      
      if (!mounted) return;
      setState(() {
        _employees = employees;
        _filterEmployees();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çalışanlar yüklenirken hata oluştu: $e')),
      );
    }
  }

  void _onEmployeeSelected(CompanyUserModel? employee) {
    if (employee == null) return; // Should not happen with new design
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceSelectionPage(
          barberId: widget.barberId,
          barberName: widget.barberName,
          barberImage: widget.barberImage,
          branch: widget.branch,
          selectedEmployee: employee,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Çalışan Seçimi',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar - Only if > 5 employees
                  if (_employees.length > 5) ...[
                    TextField(
                      controller: _searchController,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Çalışan Ara...',
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  if (_filteredEmployees.isNotEmpty) ...[
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85, // Adjust for card height
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                        ),
                        itemCount: _filteredEmployees.length,
                        itemBuilder: (context, index) {
                          return _buildEmployeeCard(_filteredEmployees[index]);
                        },
                      ),
                    ),
                  ] else if (!_isLoading) ...[
                     Expanded(
                      child: Center(
                        child: Text(
                          'Çalışan bulunamadı.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEmployeeCard(CompanyUserModel employee) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.06),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.backgroundSecondary,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      image: (employee.userDetail.picture != null && 
                              employee.userDetail.picture!.isNotEmpty)
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                employee.userDetail.picture!.startsWith('http')
                                    ? employee.userDetail.picture!
                                    : '${ApiConstants.fileUrl}${employee.userDetail.picture!}',
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (employee.userDetail.picture == null || 
                            employee.userDetail.picture!.isEmpty)
                        ? Center(
                            child: Text(
                              employee.userDetail.name.isNotEmpty
                                  ? employee.userDetail.name[0].toUpperCase()
                                  : '?',
                              style: AppTypography.h5.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  
                  // Name
                  Text(
                    '${employee.userDetail.name} ${employee.userDetail.surname}',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Çalışan',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Top Right "Seç" Button
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Seç',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),

          // Interaction Overlay
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _onEmployeeSelected(employee),
                splashColor: AppColors.primary.withOpacity(0.08),
                highlightColor: AppColors.primary.withOpacity(0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
