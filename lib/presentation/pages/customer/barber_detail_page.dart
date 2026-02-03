import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/performance_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/messaging_panel.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/company_follower_provider.dart';
import 'service_selection_page.dart';
import 'employee_selection_page.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/company_service_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/services/branch_api_service.dart';
import '../../../data/services/company_service_api_service.dart';
import '../../../data/services/comment_api_service.dart';
import '../../../data/models/comment_model.dart';
import '../../../domain/usecases/post_usecases.dart';
import '../../../data/repositories/post_repository_impl.dart';
import '../../../data/services/post_like_api_service.dart';

import '../../widgets/image_gallery.dart';

class BarberDetailPage extends StatefulWidget {
  final String companyId;

  const BarberDetailPage({super.key, required this.companyId});

  @override
  State<BarberDetailPage> createState() => _BarberDetailPageState();
}

class _BarberDetailPageState extends State<BarberDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late PageController _pageController;
  bool _isAppBarCollapsed = false;
  int _currentPageIndex = 0;

  // API Services
  final BranchApiService _branchApiService = BranchApiService();
  final CompanyServiceApiService _companyServiceApiService =
      CompanyServiceApiService();
  final PostUseCases _postUseCases = PostUseCases(PostRepositoryImpl());
  final CommentApiService _commentApiService = CommentApiService();

  // Data Models
  BranchModel? _branch;
  List<CompanyServiceModel> _services = [];
  List<PostModel> _posts = [];
  List<PostModel> _allPosts = []; // Store all posts
  List<CommentModel> _comments = [];
  double _averageRating = 3.0; // Default starting rating
  int _totalReviews = 0;
  bool _isLoading = true;
  bool _isLoadingComments = false;
  String? _errorMessage;

  // Posts pagination
  int _postsPage = 1;
  final int _postsPerPage = 12; // Instagram benzeri - 4 satır x 3 sütun
  bool _isLoadingMorePosts = false;
  bool _hasMorePosts = true;
  late ScrollController _postsScrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _postsScrollController = ScrollController();
    _pageController = PageController();

    _scrollController.addListener(() {
      final isCollapsed = _scrollController.offset > 200;
      if (isCollapsed != _isAppBarCollapsed) {
        setState(() {
          _isAppBarCollapsed = isCollapsed;
        });
      }
    });

    _postsScrollController.addListener(_onPostsScroll);

    _loadData();
  }

  void _onPostsScroll() {
    if (_postsScrollController.hasClients &&
        _postsScrollController.position.pixels >=
            _postsScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMorePosts &&
        _hasMorePosts) {
      _loadMorePosts();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _postsScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Open map navigation for the business location
  Future<void> _openMapNavigation() async {
    if (_branch?.latitude == null || _branch?.longitude == null) {
      return;
    }

    final lat = _branch!.latitude!;
    final lng = _branch!.longitude!;
    final businessName = _branch!.name;

    // Create platform-specific URLs
    String url;

    // Check if running on iOS
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // iOS - Apple Maps (more reliable format)
      url =
          'http://maps.apple.com/?q=${Uri.encodeComponent(businessName)}&ll=$lat,$lng';
    } else {
      // Android - Google Maps or system default
      url = 'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(businessName)})';
    }

    try {
      final uri = Uri.parse(url);

      // Try to launch the URL directly without canLaunchUrl check first
      // This often works better on iOS
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return; // Success, exit early
      } catch (e) {
        // Try with canLaunchUrl check
      }

      // If direct launch fails, try with canLaunchUrl check
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Google Maps web version
        final fallbackUrl =
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
        final fallbackUri = Uri.parse(fallbackUrl);

        try {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Harita uygulaması açılamadı'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harita açılırken hata oluştu'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Make a phone call to the business
  Future<void> _makePhoneCall() async {
    if (_branch?.phone == null || _branch!.phone.isEmpty) {
      return;
    }

    final phoneNumber = _branch!.phone;
    final formattedNumber = _formatPhoneForCall(phoneNumber);
    final displayNumber = _formatPhoneNumber(phoneNumber);

    try {
      final uri = Uri.parse('tel:$formattedNumber');

      // Try to launch the tel: URL directly first
      try {
        await launchUrl(uri);
        return; // Success, exit early
      } catch (e) {
        // Try with canLaunchUrl check
      }

      // If direct launch fails, check if URL can be launched
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Show a more helpful message with the phone number
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Telefon uygulaması açılamadı'),
                  Text(
                    'Numarayı manuel olarak arayın: $displayNumber',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Kopyala',
                textColor: Colors.white,
                onPressed: () {
                  // Copy phone number to clipboard
                  Clipboard.setData(ClipboardData(text: formattedNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Telefon numarası kopyalandı'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arama başlatılırken hata oluştu'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Format phone number for display
  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // If it starts with 90, format as Turkish number
    if (digitsOnly.startsWith('90') && digitsOnly.length == 12) {
      // Format: +90 XXX XXX XX XX
      final withoutCountryCode = digitsOnly.substring(2);
      return '+90 ${withoutCountryCode.substring(0, 3)} ${withoutCountryCode.substring(3, 6)} ${withoutCountryCode.substring(6, 8)} ${withoutCountryCode.substring(8)}';
    }

    // If it starts with 5 and is 11 digits, add +90
    if (digitsOnly.startsWith('5') && digitsOnly.length == 11) {
      final formatted =
          '+90 ${digitsOnly.substring(1, 4)} ${digitsOnly.substring(4, 7)} ${digitsOnly.substring(7, 9)} ${digitsOnly.substring(9)}';
      return formatted;
    }

    // If it starts with 0 and is 11 digits, format as Turkish number
    if (digitsOnly.startsWith('0') && digitsOnly.length == 11) {
      final withoutZero = digitsOnly.substring(1);
      return '+90 ${withoutZero.substring(0, 3)} ${withoutZero.substring(3, 6)} ${withoutZero.substring(6, 8)} ${withoutZero.substring(8)}';
    }

    // Default: return original if can't format
    return phone;
  }

  /// Format phone number for calling (tel: URL)
  String _formatPhoneForCall(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // If it already starts with country code, use as is
    if (digitsOnly.startsWith('90') && digitsOnly.length == 12) {
      return '+$digitsOnly';
    }

    // If it starts with 0, remove it and add +90
    if (digitsOnly.startsWith('0') && digitsOnly.length == 11) {
      return '+90${digitsOnly.substring(1)}';
    }

    // If it starts with 5 and is 11 digits, add +90
    if (digitsOnly.startsWith('5') && digitsOnly.length == 11) {
      return '+90$digitsOnly';
    }

    // Default: add +90 if it's a valid Turkish mobile number
    if (digitsOnly.length == 11 && digitsOnly.startsWith('5')) {
      return '+90$digitsOnly';
    }

    // Fallback: return original with +
    return '+$digitsOnly';
  }

  /// Share branch information
  Future<void> _shareBranch() async {
    if (_branch == null) return;

    final branchName = _branch!.name;
    final branchLink = 'https://app.mandw.com.tr/company-detail/${_branch!.id}';
    final shareText =
        '$branchName işletmesine göz at! Randevu ve detaylar: $branchLink';

    try {
      // iPad için güvenli bir alan belirleyelim (ekranın ortası)
      final Size size = MediaQuery.of(context).size;
      // Rect boyutu 0 olmamalı, en az 1x1 olmalı
      final Rect shareOrigin = Rect.fromLTWH(
        size.width / 2,
        size.height / 2,
        10, // Width > 0
        10, // Height > 0
      );

      await Share.share(
        shareText,
        subject: branchName,
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım hatası: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ),
        );
      }
      print('Share error: $e'); // Debug için
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load branch details first to get parent company ID
      await _loadBranchDetails();

      // Load other data in parallel
      await Future.wait([
        _loadCompanyServices(),
        _loadPosts(),
        _loadComments(),
        _loadPosts(),
        _loadComments(),
        _loadRatingStats(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadBranchDetails() async {
    try {
      _branch = await _branchApiService.getBranch(widget.companyId);
      
      if (_branch?.followerCount != null && mounted) {
        Provider.of<CompanyFollowerProvider>(context, listen: false)
            .setFollowerCount(widget.companyId, _branch!.followerCount!);
      }
    } catch (e) {
      // Continue without branch details
    }
  }

  Future<void> _loadCompanyServices() async {
    try {
      _services = await _companyServiceApiService.getCompanyServicesByCompanyId(
        widget.companyId,
        parentCompanyId: _branch?.companyId,
      );
    } catch (e) {
      _services = [];
    }
  }

  Future<void> _loadPosts() async {
    try {
      // Determine which identifier to use for post query
      String postCompanyId = widget.companyId;

      // Ensure branch details are loaded so we can use the canonical branch ID
      if (_branch == null) {
        try {
          _branch = await _branchApiService.getBranch(widget.companyId);
        } catch (e) {
          // Continue with existing identifier even if branch lookup fails
        }
      }

      if (_branch != null && _branch!.id.isNotEmpty) {
        postCompanyId = _branch!.id;
      }

      _allPosts = await _postUseCases.getPostsByCompany(postCompanyId);

      // Initially show first page of posts
      _posts = _allPosts.take(_postsPerPage).toList();
      _hasMorePosts = _allPosts.length > _postsPerPage;
      _postsPage = 1;
    } catch (e) {
      // If API fails, show empty list
      _allPosts = [];
      _posts = [];
      _hasMorePosts = false;
      _postsPage = 1;
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMorePosts || !_hasMorePosts) return;

    setState(() {
      _isLoadingMorePosts = true;
    });

    // Simulate a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _postsPage++;
      final startIndex = (_postsPage - 1) * _postsPerPage;
      final endIndex = startIndex + _postsPerPage;

      if (endIndex < _allPosts.length) {
        _posts = _allPosts.take(endIndex).toList();
        _hasMorePosts = endIndex < _allPosts.length;
      } else {
        _posts = _allPosts;
        _hasMorePosts = false;
      }

      _isLoadingMorePosts = false;
    });
  }

  Future<void> _loadComments() async {
    try {
      setState(() {
        _isLoadingComments = true;
      });

      _comments = await _commentApiService.getComments(
        companyId: widget.companyId,
        page: 1,
        limit: 50, // Load more comments initially
      );

      // Also update rating stats when comments are loaded
      await _loadRatingStats();

      setState(() {
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
        _comments = []; // Show empty list if API fails
      });
    }
  }

  Future<void> _loadRatingStats() async {
    try {
      final stats = await _commentApiService.getCompanyRatingStats(
        companyId: widget.companyId,
      );

      setState(() {
        _averageRating = stats['averageRating'] as double? ?? 3.0;
        _totalReviews = stats['totalReviews'] as int? ?? 0;
      });
    } catch (e) {
      // Keep default values if API fails
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null && _branch == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Bir hata oluştu',
                style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildSliverAppBar(),
            _buildProfileInfo(),
            _buildServicesSection(),
            _buildFeaturesSection(),
            _buildTabSection(),
            _buildTabBarViewContent(),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Navigation bar spacing
            ),
          ],
        ),
      ),
      floatingActionButton: _buildBookingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        // Favorite Button
        Consumer<FavoriteProvider>(
          builder: (context, favoriteProvider, child) {
            final isFavorite = favoriteProvider.isFavorite(widget.companyId);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, animationValue, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * animationValue),
                  child: Container(
                    margin: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? AppColors.error : Colors.white,
                        size: 22,
                      ),
                      onPressed: () async {
                        try {
                          await favoriteProvider
                              .toggleFavorite(widget.companyId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFavorite
                                      ? 'Favorilerden çıkarıldı'
                                      : 'Favorilere eklendi',
                                ),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Hata: ${e.toString().replaceFirst('Exception: ', '')}',
                                ),
                                backgroundColor: AppColors.error,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
        Container(
          margin: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: _openMessaging,
          ),
        ),
        // Phone call icon - only show if phone number exists
        if (_branch?.phone != null && _branch!.phone.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.phone_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _makePhoneCall,
            ),
          ),
        // Share button
        Container(
          margin: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: _shareBranch,
          ),
        ),
        // Follow Button

      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Interior images as background with PageView - wrapped in Positioned.fill
            if (_branch?.interiorImages != null &&
                _branch!.interiorImages!.isNotEmpty)
              Positioned.fill(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _branch!.interiorImages!.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = _branch!.interiorImages![index];
                    return GestureDetector(
                      onTap: () {
                        _showImageGallery(_branch!.interiorImages!, index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.8),
                                    AppColors.secondary.withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                            );
                          },
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.3),
                                  AppColors.secondary.withValues(alpha: 0.2),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (_branch?.image != null)
              CachedNetworkImage(
                imageUrl: _branch!.image!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                          AppColors.secondary.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  );
                },
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.secondary.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.secondary.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),

            // Enhanced gradient overlay for better text readability - with IgnorePointer
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Profile photo in square box
            Positioned(
              bottom: 50,
              left: AppSpacing.screenHorizontal,
              child: Hero(
                tag: 'barber_${widget.companyId}',
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: _branch?.image != null
                        ? Image.network(
                            _branch!.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.backgroundSecondary,
                                child: Icon(
                                  Icons.business,
                                  size: 60,
                                  color: AppColors.textTertiary,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.backgroundSecondary,
                            child: Icon(
                              Icons.business,
                              size: 60,
                              color: AppColors.textTertiary,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // Verified badge removed per design

            // Page indicator dots
            if (_branch?.interiorImages != null &&
                _branch!.interiorImages!.isNotEmpty)
              Positioned(
                bottom: 70,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _branch!.interiorImages!.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPageIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildProfileInfo() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Name and Follow Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _branch?.name ?? AppLocalizations.of(context)!.barberSalon,
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Consumer<CompanyFollowerProvider>(
                  builder: (context, provider, _) {
                    final isFollowing = provider.isFollowing(widget.companyId);
                    return GestureDetector(
                      onTap: () async {
                        try {
                          await provider.toggleFollow(widget.companyId);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('İşlem başarısız: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isFollowing
                              ? Colors.transparent
                              : AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(
                            color: isFollowing
                                ? AppColors.textSecondary.withValues(alpha: 0.5)
                                : AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          isFollowing ? AppLocalizations.of(context)!.following : AppLocalizations.of(context)!.follow,
                          style: AppTypography.bodySmall.copyWith(
                            color: isFollowing
                                ? AppColors.textSecondary
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Row 2: Stats (Rating | Reviews | Followers)
            GestureDetector(
              onTap: () {
                // Navigate to comments tab
                if (_tabController.length > 2) {
                  _tabController.animateTo(2); // Comments tab index
                }
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 20,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($_totalReviews Yorum)',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Consumer<CompanyFollowerProvider>(
                    builder: (context, provider, _) {
                      final count = provider.getFollowerCount(widget.companyId);
                      return Text(
                        AppLocalizations.of(context)!.followers(count),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Row 3: Location and Type Buttons (Existing logic)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusLg,
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: GestureDetector(
                    onTap: _branch?.latitude != null &&
                            _branch?.longitude != null
                        ? () => _openMapNavigation()
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            (_branch?.latitude != null &&
                                    _branch?.longitude != null)
                                ? AppLocalizations.of(context)!.showOnMap
                                : (_branch?.address ??
                                    AppLocalizations.of(context)!
                                        .noLocationInfo),
                            style: AppTypography.bodySmall.copyWith(
                              color: (_branch?.latitude != null &&
                                      _branch?.longitude != null)
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_branch?.latitude != null &&
                            _branch?.longitude != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.map_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_branch?.type != null && _branch!.type.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusLg,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _branch!.type,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }




  SliverToBoxAdapter _buildServicesSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.content_cut_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  AppLocalizations.of(context)!.ourServices,
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                if (_services.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.1),
                          AppColors.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${_services.length}',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_services.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.noServicesMessage,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.35,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                ),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return _buildPremiumServiceCard(service, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumServiceCard(CompanyServiceModel service, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animationValue),
          child: Opacity(
            opacity: animationValue,
            child: GestureDetector(
              onTap: () {
                // Haptic feedback
                HapticFeedback.lightImpact();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.surface, AppColors.backgroundSecondary],
                  ),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Gradient accent line on top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppSpacing.radiusXxl),
                            topRight: Radius.circular(AppSpacing.radiusXxl),
                          ),
                        ),
                      ),
                    ),

                    // Shimmer effect overlay
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXxl,
                        ),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: -1.0, end: 2.0),
                          duration: const Duration(milliseconds: 2000),
                          curve: Curves.easeInOut,
                          builder: (context, shimmerValue, child) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.05),
                                    Colors.transparent,
                                  ],
                                  stops: [
                                    (shimmerValue - 0.3).clamp(0.0, 1.0),
                                    shimmerValue.clamp(0.0, 1.0),
                                    (shimmerValue + 0.3).clamp(0.0, 1.0),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Top section: Icon and Name
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.content_cut_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  service.serviceName ??
                                      AppLocalizations.of(context)!
                                          .serviceDefaultName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Bottom section: Duration and Price
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Duration (Above Price)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.info.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                    border: Border.all(
                                      color:
                                          AppColors.info.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 11,
                                        color: AppColors.info,
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          service.durationDisplay,
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.info,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 9,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Price
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.success
                                            .withValues(alpha: 0.15),
                                        AppColors.success
                                            .withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                    border: Border.all(
                                      color: AppColors.success
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.payments_rounded,
                                        size: 12,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          service.priceDisplay,
                                          style:
                                              AppTypography.bodyMedium.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _buildFeaturesSection() {
    final features = _branch?.services ?? [];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  AppLocalizations.of(context)!.features,
                  style: AppTypography.h5.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (features.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.noFeatureInfo,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: features.asMap().entries.map((entry) {
                  final index = entry.key;
                  final feature = entry.value;
                  return _buildFeatureChip(feature, index);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String feature, int index) {
    final icon = _getFeatureIcon(feature);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animationValue),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(icon, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      feature,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Removed color pairs; feature chips use AppColors.primary for consistency

  IconData _getFeatureIcon(String featureName) {
    final name = featureName.toLowerCase();
    if (name.contains('wifi') || name.contains('internet')) {
      return Icons.wifi;
    } else if (name.contains('klima') || name.contains('air')) {
      return Icons.ac_unit;
    } else if (name.contains('otopark') || name.contains('park')) {
      return Icons.local_parking;
    } else if (name.contains('engelli') || name.contains('accessible')) {
      return Icons.accessible;
    } else if (name.contains('kart') ||
        name.contains('card') ||
        name.contains('ödeme')) {
      return Icons.credit_card;
    } else if (name.contains('randevu') ||
        name.contains('appointment') ||
        name.contains('online')) {
      return Icons.schedule;
    } else if (name.contains('tv') || name.contains('televizyon')) {
      return Icons.tv;
    } else if (name.contains('müzik') || name.contains('music')) {
      return Icons.music_note;
    } else if (name.contains('temizlik') || name.contains('clean')) {
      return Icons.cleaning_services;
    } else if (name.contains('güvenlik') || name.contains('security')) {
      return Icons.security;
    } else {
      return Icons.check_circle;
    }
  }

  SliverToBoxAdapter _buildTabSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.xxl,
          AppSpacing.screenHorizontal,
          AppSpacing.lg,
        ),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_on_rounded, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(AppLocalizations.of(context)!.postsTab),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.comment_rounded, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(AppLocalizations.of(context)!.commentsTab),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarViewContent() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        height: MediaQuery.of(context).size.height * 0.6,
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildPostsTab(), _buildCommentsTab()],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty && !_isLoading) {
      return Container(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.1),
                      AppColors.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppLocalizations.of(context)!.noPostsYet,
                style: AppTypography.h6.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context)!.noPostsMessage,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildInstagramGrid();
  }

  Widget _buildCommentsTab() {
    if (_isLoadingComments) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.noCommentsYet,
              style: AppTypography.h6.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'İlk yorumu siz yapın!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComments,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _comments.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          final comment = _comments[index];
          return _buildCommentCard(comment);
        },
      ),
    );
  }

  Widget _buildCommentCard(CommentModel comment) {
    final trimmedComment = comment.comment.trim();
    final hasCommentText = trimmedComment.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.backgroundSecondary],
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
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: hasCommentText
          ? _buildCommentWithText(comment, trimmedComment)
          : _buildRatingOnlyComment(comment),
    );
  }

  Widget _buildRatingOnlyComment(CommentModel comment) {
    final dateLabel = _buildCommentDateLabel(comment);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCommentAvatar(comment),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.maskedFullName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildStarRating(comment.rating),
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

  Widget _buildCommentWithText(CommentModel comment, String commentText) {
    final dateLabel = _buildCommentDateLabel(comment);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCommentAvatar(comment),
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
        _buildStarRating(comment.rating),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Text(
            commentText,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
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

  Widget _buildCommentAvatar(CommentModel comment) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: comment.customerImage != null
            ? Image.network(
                comment.customerImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primary,
                    child: const Icon(
                      Icons.person_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  );
                },
              )
            : Container(
                color: AppColors.primary,
                child: const Icon(
                  Icons.person_rounded,
                  size: 24,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget? _buildCommentDateLabel(CommentModel comment) {
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
      softWrap: false,
    );
  }

  Widget _buildInstagramGrid() {
    return GridView.builder(
      controller: _postsScrollController,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _posts.length + (_hasMorePosts ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == _posts.length) {
          return Container(
            color: AppColors.backgroundSecondary,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final post = _posts[index];
        final imageUrl = post.files.isNotEmpty ? post.files.first : null;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showPostDetail(post);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth:
                      PerformanceUtils.getIOSImageCacheWidth(context),
                  memCacheHeight:
                      PerformanceUtils.getIOSImageCacheHeight(context),
                  maxWidthDiskCache: 300,
                  maxHeightDiskCache: 300,
                  errorWidget: (context, url, error) {
                    return Container(
                      color: AppColors.backgroundSecondary,
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.textTertiary,
                        size: 24,
                      ),
                    );
                  },
                  placeholder: (context, url) => Container(
                    color: AppColors.backgroundSecondary,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  color: AppColors.backgroundSecondary,
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.textTertiary,
                    size: 24,
                  ),
                ),

              // Tap overlay effect
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showPostDetail(post);
                    },
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Video indicator
              if (imageUrl != null && _isVideoFile(imageUrl))
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),

              // Multiple images indicator
              if (post.files.length > 1)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.collections_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${post.files.length}',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isVideoFile(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    return videoExtensions.any((ext) => url.toLowerCase().contains(ext));
  }

  Widget _buildBookingButton() {
    return Container(
      width:
          MediaQuery.of(context).size.width - (AppSpacing.screenHorizontal * 2),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeSelectionPage(
                    barberId: widget.companyId,
                    barberName: _branch?.name ?? 'İşletme',
                    barberImage: _branch?.image ?? '',
                    branch: _branch, // Branch bilgisini geçir
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    AppLocalizations.of(context)!.appointmentButton,
                    style: AppTypography.h6.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMessaging() {
    // Mesajlaşma panelini aç
    _showMessagingPanel();
  }

  void _showMessagingPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MessagingPanel(
        receiverName: _branch?.name ?? 'İşletme',
        receiverImage: _branch?.image ?? '',
        receiverId: widget.companyId,
        companyId: widget.companyId, // Company ID'yi ekle
      ),
    );
  }

  void _showPostDetail(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PostDetailModal(
        post: post,
        branch: _branch,
        onLikeChanged: (isLiked, likeCount) {
          setState(() {
            // Update _posts list
            final postIndex = _posts.indexWhere((p) => p.id == post.id);
            if (postIndex != -1) {
              _posts[postIndex] = _posts[postIndex].copyWith(
                isLiked: isLiked,
                likeCount: likeCount,
              );
            }

            // Update _allPosts list too
            final allPostIndex = _allPosts.indexWhere((p) => p.id == post.id);
            if (allPostIndex != -1) {
              _allPosts[allPostIndex] = _allPosts[allPostIndex].copyWith(
                isLiked: isLiked,
                likeCount: likeCount,
              );
            }
          });
        },
      ),
    );
  }

  void _showImageGallery(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ImageGallery(images: images, initialIndex: initialIndex),
      ),
    );
  }
}

class _PostDetailModal extends StatefulWidget {
  final PostModel post;
  final BranchModel? branch;
  final Function(bool isLiked, int likeCount)? onLikeChanged;

  const _PostDetailModal({
    required this.post,
    this.branch,
    this.onLikeChanged,
  });

  @override
  State<_PostDetailModal> createState() => _PostDetailModalState();
}

class _PostDetailModalState extends State<_PostDetailModal> {
  late PageController _pageController;
  int _currentImageIndex = 0;
  
  // Like state
  final PostLikeApiService _postLikeApiService = PostLikeApiService();
  late bool _isLiked;
  late int _likeCount;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;

    // Optimistic update
    setState(() {
      _isLiking = true;
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
    });

    // Notify parent immediately
    widget.onLikeChanged?.call(_isLiked, _likeCount);

    try {
      await _postLikeApiService.likePost(widget.post.id);
      
      // Haptic feedback for success
      HapticFeedback.mediumImpact();
    } catch (e) {
      // Revert if error
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          if (_isLiked) {
            _likeCount++;
          } else {
            _likeCount--;
          }
        });
        
        // Notify parent about revert
        widget.onLikeChanged?.call(_isLiked, _likeCount);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem başarısız oldu'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface, AppColors.backgroundSecondary],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 48,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.3),
                  AppColors.secondary.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image carousel
                  if (widget.post.files.isNotEmpty)
                    Stack(
                      children: [
                        Container(
                          height: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXxl,
                            ),
                          ),
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemCount: widget.post.files.length,
                            itemBuilder: (context, index) {
                              final imageUrl = widget.post.files[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImageGallery(
                                        images: widget.post.files,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusXxl,
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: 400,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 400,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.accent
                                                  .withValues(alpha: 0.1),
                                              AppColors.secondary.withValues(
                                                alpha: 0.05,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusXxl,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 64,
                                          color: AppColors.textTertiary,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Image counter indicator
                        if (widget.post.files.length > 1)
                          Positioned(
                            top: AppSpacing.lg,
                            right: AppSpacing.lg,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.7),
                                    Colors.black.withValues(alpha: 0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.collections_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_currentImageIndex + 1}/${widget.post.files.length}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Page indicators
                        if (widget.post.files.length > 1)
                          Positioned(
                            bottom: AppSpacing.lg,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.post.files.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.md),
                  
                  // Action Buttons Row (Like, etc.)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                          child: Row(
                            children: [
                              TweenAnimationBuilder<double>(
                                key: ValueKey(_isLiked),
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutBack,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: _isLiked 
                                      ? 1.0 + (0.2 * value) 
                                      : 1.0,
                                    child: Icon(
                                      _isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                                      color: _isLiked ? AppColors.error : AppColors.textPrimary,
                                      size: 32,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              if (_likeCount > 0)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return ScaleTransition(scale: animation, child: child);
                                  },
                                  child: Text(
                                    '$_likeCount',
                                    key: ValueKey<int>(_likeCount),
                                    style: AppTypography.h6.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.md),

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      widget.post.description.isNotEmpty 
                          ? widget.post.description 
                          : 'Açıklama yok',
                      style: AppTypography.bodyLarge.copyWith(
                        height: 1.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Branch info
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.surface,
                          AppColors.backgroundSecondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Branch avatar
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: widget.branch?.image != null
                              ? ClipOval(
                                  child: Image.network(
                                    widget.branch!.image!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return const Icon(
                                        Icons.content_cut_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.content_cut_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.branch?.name ?? 'İşletme',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: AppColors.textTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatCommentDate(widget.post.createdAt),
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCommentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks hafta önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
