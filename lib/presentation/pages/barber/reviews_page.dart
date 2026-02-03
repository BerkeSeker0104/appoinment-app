import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/repositories/comment_repository_impl.dart';
import '../../../domain/usecases/comment_usecases.dart';

class ReviewsPage extends StatefulWidget {
  final String companyId;

  const ReviewsPage({
    super.key,
    required this.companyId,
  });

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  late final CommentUseCases _commentUseCases;
  List<CommentModel> _comments = [];
  Map<String, dynamic> _ratingStats = {
    'averageRating': 0.0,
    'totalReviews': 0,
  };
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _commentUseCases = CommentUseCases(CommentRepositoryImpl());
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        _commentUseCases.fetchCompanyComments(companyId: widget.companyId),
        _commentUseCases.fetchCompanyRatingStats(companyId: widget.companyId),
      ]);

      if (mounted) {
        setState(() {
          _comments = results[0] as List<CommentModel>;
          _ratingStats = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_isLoading && _errorMessage == null) _buildStatsRow(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildReviewsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Yorumlar yüklenirken hata oluştu',
            style: AppTypography.body1,
          ),
          TextButton(
            onPressed: _loadData,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yorumlar',
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Müşteri değerlendirmeleri',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final averageRating =
        (_ratingStats['averageRating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews = (_ratingStats['totalReviews'] as num?)?.toInt() ?? 0;

    // Count comments with text (actual reviews vs just ratings)
    final commentsCount = _comments.where((c) => c.comment.isNotEmpty).length;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Ortalama Puan',
            averageRating.toStringAsFixed(1),
            Icons.star,
            Colors.amber,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Toplam Puan',
            totalReviews.toString(),
            Icons.star_half,
            AppColors.primary,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Yorum Sayısı',
            commentsCount.toString(),
            Icons.comment,
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    );
  }

  Widget _buildReviewsList() {
    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: AppColors.textQuaternary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Henüz yorum yok',
              style: AppTypography.h6.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Müşterilerinizden gelen yorumlar burada görünecek',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: _comments.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildReviewCard(comment);
      },
    );
  }

  Widget _buildReviewCard(CommentModel comment) {
    final trimmedComment = comment.comment.trim();
    final hasCommentText = trimmedComment.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.backgroundSecondary,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: hasCommentText
          ? _buildTextReviewContent(comment, trimmedComment)
          : _buildRatingOnlyContent(comment),
    );
  }

  Widget _buildRatingOnlyContent(CommentModel comment) {
    final dateLabel = _buildDateLabel(comment);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAvatar(comment),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  comment.maskedFullName,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildStarRating(comment.score),
            ],
          ),
        ),
        if (dateLabel != null) ...[
          const SizedBox(width: AppSpacing.md),
          Flexible(
            flex: 0,
            child: dateLabel,
          ),
        ],
      ],
    );
  }

  Widget _buildTextReviewContent(CommentModel comment, String commentText) {
    final dateLabel = _buildDateLabel(comment);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(comment),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                comment.maskedFullName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (dateLabel != null) ...[
              const SizedBox(width: AppSpacing.md),
              dateLabel,
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildStarRating(comment.score),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            commentText,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? Colors.amber : AppColors.border,
          size: 16,
        );
      }),
    );
  }

  Widget _buildAvatar(CommentModel comment) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        color: AppColors.backgroundSecondary,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: comment.customerImage != null
            ? Image.network(
                comment.customerImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 24,
                    color: AppColors.textTertiary,
                  );
                },
              )
            : const Icon(
                Icons.person,
                size: 24,
                color: AppColors.textTertiary,
              ),
      ),
    );
  }

  Widget? _buildDateLabel(CommentModel comment) {
    final formattedDate = comment.formattedDate;
    if (formattedDate.isEmpty) return null;

    return Text(
      formattedDate,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // void _replyToReview(CommentModel comment) {
  //   // Implementation for reply
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Yanıt özelliği yakında eklenecek')),
  //   );
  // }
}
