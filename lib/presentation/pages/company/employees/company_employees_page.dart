import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../domain/usecases/company_user_usecases.dart';
import '../../../../data/models/company_user_model.dart';
import '../../../../core/constants/api_constants.dart';
import 'widgets/company_employee_modal.dart';

class CompanyEmployeesPage extends StatefulWidget {
  final String? companyId;
  final bool hideBackButton;

  const CompanyEmployeesPage({
    Key? key, 
    this.companyId,
    this.hideBackButton = false,
  }) : super(key: key);

  @override
  State<CompanyEmployeesPage> createState() => _CompanyEmployeesPageState();
}

class _CompanyEmployeesPageState extends State<CompanyEmployeesPage> {
  final CompanyUserUseCases _companyUserUseCases = CompanyUserUseCases();
  bool _isLoading = true;
  List<CompanyUserModel> _employees = [];
  String? _resolvedCompanyId;
  
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'pending', 'active'

  @override
  void initState() {
    super.initState();
    _resolvedCompanyId = widget.companyId;
    _fetchEmployees();
  }

  Color _getStateColor(String state) {
    switch (state) {
      case '2':
        return Colors.green;
      case '3':
        return Colors.red;
      case '0':
      case '1':
      default:
        return Colors.orange;
    }
  }

  String _getStateText(String state) {
    switch (state) {
      case '2':
        return 'Onaylandı';
      case '3':
        return 'Yasaklandı';
      case '0':
      case '1':
      default:
        return 'Onay Bekliyor';
    }
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final result = await _companyUserUseCases.getCompanyUsers(
        page: 1,
        dataCount: 100, // Fetch all reasonable amount
      );
      
      if (result['data'] != null) {
        setState(() {
          _employees = result['data'];
          if (_resolvedCompanyId == null && _employees.isNotEmpty) {
            _resolvedCompanyId = _employees.first.companyId;
          }
          debugPrint('Resolved companyId: $_resolvedCompanyId');
          if (_employees.isNotEmpty) {
            debugPrint('First employee companyId: ${_employees.first.companyId}');
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEmployeeModal([CompanyUserModel? employee]) {
    if (_resolvedCompanyId == null && employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.companyInfoNotFound)),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompanyEmployeeModal(
        employee: employee,
        companyId: employee?.companyId ?? _resolvedCompanyId!,
        onSuccess: _fetchEmployees,
      ),
    );
  }

  Future<void> _deleteEmployee(CompanyUserModel employee) async {
    try {
      await _companyUserUseCases.deleteCompanyUser(
        userId: employee.userId,
        companyId: employee.companyId,
      );
      
      if (!mounted) return;

      _fetchEmployees();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Çalışan silindi'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }

  List<CompanyUserModel> _getFilteredEmployees() {
    return _employees.where((employee) {
      // 1. Search Filter
      final fullName = employee.userDetail.fullName.toLowerCase();
      final phone = employee.userDetail.phone;
      final query = _searchQuery.toLowerCase();
      final matchesSearch = fullName.contains(query) || phone.contains(query);

      // 2. Status Filter
      bool matchesStatus = true;
      if (_selectedFilter == 'pending') {
        matchesStatus = employee.state == '0' || employee.state == '1';
      } else if (_selectedFilter == 'active') {
        matchesStatus = employee.state == '2'; // Assuming 2 is Active/Approved
      } 
      // 'all' includes everything

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _getFilteredEmployees();
    final bottomPadding = widget.hideBackButton ? 100.0 : 16.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.hideBackButton 
          ? null 
          : AppBar(
              title: Text(AppLocalizations.of(context)!.employees, style: AppTypography.heading3),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: !widget.hideBackButton,
              leading: widget.hideBackButton ? null : const BackButton(color: AppColors.textPrimary),
              actions: [
                IconButton(
                  onPressed: () => _showEmployeeModal(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: AppColors.primary, size: 24),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (widget.hideBackButton) const SizedBox(height: 16),
                // Search Bar and Add Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.searchPlaceholder,
                            hintStyle: AppTypography.body2.copyWith(color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.surfaceCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                      if (widget.hideBackButton) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showEmployeeModal(),
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 28),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip(AppLocalizations.of(context)!.allFilters, 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Onay Bekleyenler', 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Aktifler', 'active'),
                    ],
                  ),
                ),
                // Employee List
                Expanded(
                  child: filteredEmployees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                'Çalışan bulunamadı',
                                style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = filteredEmployees[index];
                            return _buildEmployeeCard(employee);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: AppTypography.body2.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(CompanyUserModel employee) {
    if (employee.isOwner) {
       return _buildCardContent(employee);
    }

    return Dismissible(
      key: Key(employee.userId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            title: Text(AppLocalizations.of(context)!.deleteEmployee, style: AppTypography.heading3),
            content: Text(
              '${employee.userDetail.fullName} adlı çalışanı silmek istediğinize emin misiniz?',
              style: AppTypography.body1,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel, style: AppTypography.buttonMedium.copyWith(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.delete, style: AppTypography.buttonMedium.copyWith(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteEmployee(employee);
      },
      child: _buildCardContent(employee),
    );
  }

  Widget _buildCardContent(CompanyUserModel employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: (employee.userDetail.picture != null && employee.userDetail.picture!.isNotEmpty)
                  ? CachedNetworkImageProvider(
                      employee.userDetail.picture!.startsWith('http') 
                          ? employee.userDetail.picture! 
                          : '${ApiConstants.fileUrl}${employee.userDetail.picture!}'
                    )
                  : null,
              child: (employee.userDetail.picture == null || employee.userDetail.picture!.isEmpty)
                  ? Text(
                      employee.userDetail.name.isNotEmpty
                          ? employee.userDetail.name[0].toUpperCase()
                          : '?',
                      style: AppTypography.heading3.copyWith(color: AppColors.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.userDetail.fullName,
                    style: AppTypography.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStateColor(employee.state).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStateText(employee.state),
                          style: AppTypography.caption.copyWith(
                            color: _getStateColor(employee.state),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Contact Info
                  if (employee.userDetail.phone.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          employee.userDetail.phone,
                          style: AppTypography.body2.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  if (employee.userDetail.email != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.email, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              employee.userDetail.email!,
                              style: AppTypography.body2.copyWith(color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Actions
            IconButton(
               onPressed: () => _showEmployeeModal(employee),
               icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
