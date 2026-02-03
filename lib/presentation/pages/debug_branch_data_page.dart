import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/branch_model.dart';
import '../../../domain/usecases/branch_usecases.dart';
import '../../../data/repositories/branch_repository_impl.dart';

class DebugBranchDataPage extends StatefulWidget {
  final String branchId;

  const DebugBranchDataPage({super.key, required this.branchId});

  @override
  State<DebugBranchDataPage> createState() => _DebugBranchDataPageState();
}

class _DebugBranchDataPageState extends State<DebugBranchDataPage> {
  final BranchUseCases _branchUseCases = BranchUseCases(BranchRepositoryImpl());
  BranchModel? _branch;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBranchData();
  }

  Future<void> _loadBranchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final branch = await _branchUseCases.getBranch(widget.branchId);


      setState(() {
        _branch = branch;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Debug Branch Data',
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Error: $_errorMessage',
                    style: AppTypography.body1.copyWith(color: AppColors.error),
                  ),
                ),
              ] else if (_branch != null) ...[
                _buildDataSection('Basic Info', {
                  'ID': _branch!.id,
                  'Name': _branch!.name,
                  'Type': _branch!.type,
                  'Address': _branch!.address,
                  'Phone': _branch!.phone,
                  'Email': _branch!.email,
                  'Status': _branch!.status,
                }),
                const SizedBox(height: AppSpacing.lg),
                _buildDataSection('Location Data', {
                  'Country ID': _branch!.countryId?.toString() ?? 'null',
                  'City ID': _branch!.cityId?.toString() ?? 'null',
                  'State ID': _branch!.stateId?.toString() ?? 'null',
                  'Latitude': _branch!.latitude?.toString() ?? 'null',
                  'Longitude': _branch!.longitude?.toString() ?? 'null',
                }),
                const SizedBox(height: AppSpacing.lg),
                _buildDataSection('Payment & Features', {
                  'Paid Types': _branch!.paidTypes ?? 'null',
                  'Services Count': _branch!.services.length.toString(),
                  'Services': _branch!.services.join(', '),
                }),
                const SizedBox(height: AppSpacing.lg),
                _buildDataSection('Working Hours', {
                  'Is 24/7':
                      _branch!.workingHours.containsKey('all') ? 'Yes' : 'No',
                  'Hours': _branch!.workingHours.toString(),
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataSection(String title, Map<String, String> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: data.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key}:',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
