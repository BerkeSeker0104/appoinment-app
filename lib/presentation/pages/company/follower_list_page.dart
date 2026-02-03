import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../providers/company_follower_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/services/branch_api_service.dart';
import '../../../data/models/company_follower_model.dart';

class FollowerListPage extends StatefulWidget {
  const FollowerListPage({super.key});

  @override
  State<FollowerListPage> createState() => _FollowerListPageState();
}

class _FollowerListPageState extends State<FollowerListPage> {
  final BranchApiService _branchApiService = BranchApiService();
  String? _companyId;
  bool _isInitLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      // Get current company ID (Primary branch)
      final branches = await _branchApiService.getBranches();
      if (branches.isNotEmpty) {
        // Prefer main branch, otherwise first
        final mainBranch = branches.firstWhere(
          (b) => b.isMain, 
          orElse: () => branches.first
        );
        _companyId = mainBranch.id;
        
        if (mounted && _companyId != null) {
          // Load followers
          context.read<CompanyFollowerProvider>().loadCompanyFollowers(_companyId!);
        }
      }
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) {
        setState(() {
          _isInitLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Takipçiler',
          style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isInitLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _companyId == null
              ? _buildErrorState('İşletme bilgisi bulunamadı')
              : Consumer<CompanyFollowerProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingFollowers) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    if (provider.errorMessage != null) {
                      return _buildErrorState(provider.errorMessage!);
                    }

                    if (provider.companyFollowers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Henüz takipçiniz yok',
                              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        if (_companyId != null) {
                          await provider.loadCompanyFollowers(_companyId!);
                        }
                      },
                      color: AppColors.primary,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            color: AppColors.surface,
                            width: double.infinity,
                            child: Text(
                              'Toplam ${provider.companyFollowers.length} kişi sizi takip ediyor',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                              itemCount: provider.companyFollowers.length,
                              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final follower = provider.companyFollowers[index];
                                return _buildFollowerCard(follower);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bir hata oluştu',
            style: AppTypography.h5,
          ),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _initData,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerCard(CompanyFollowerModel follower) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundSecondary,
              border: Border.all(color: AppColors.border),
            ),
            child: follower.userProfileImage != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: follower.userProfileImage!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          Icon(Icons.person, color: AppColors.textTertiary),
                    ),
                  )
                : Icon(Icons.person, color: AppColors.textTertiary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  follower.userFullName ?? 'İsimsiz Kullanıcı',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Kayıt: ${_formatDate(follower.createdAt)}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
