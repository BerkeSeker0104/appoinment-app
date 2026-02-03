import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/branch_model.dart';
import '../../../presentation/providers/appointment_provider.dart';
import '../../widgets/premium_button.dart';
import 'booking_confirmation_page.dart';
import 'payment_webview_page.dart';
import '../../../data/models/company_user_model.dart';

class AppointmentBookingPage extends StatefulWidget {
  final String barberId;
  final String barberName;
  final String barberImage;
  final List<ServiceModel> selectedServices;
  final double totalPrice;
  final int totalDuration;
  final BranchModel? branch;

  const AppointmentBookingPage({
    super.key,
    required this.barberId,
    required this.barberName,
    required this.barberImage,
    required this.selectedServices,
    required this.totalPrice,
    required this.totalDuration,
    this.branch,
    this.selectedEmployee,
  });

  final CompanyUserModel? selectedEmployee;

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage>
    with WidgetsBindingObserver {
  // Constants
  static const int _totalSteps = 4;
  static const int _calendarDaysToShow = 30;
  static const String _defaultPaymentMethod = 'cash';
  static const String _paymentMethodCash = 'cash';
  static const String _paymentMethodCard = 'creditCard';
  static const String _paymentMethodOnline = 'online';

  late PageController _pageController;

  int _currentPage = 0;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  String _selectedPaymentMethod = _defaultPaymentMethod;

  final _cardNumberController = TextEditingController();
  final _cardExpirationMonthController = TextEditingController();
  final _cardExpirationYearController = TextEditingController();
  final _cardCvcController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _cardFormKey = GlobalKey();
  final _cardNumberFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);

    // Debug: Check if selectedEmployee is received
    debugPrint('AppointmentBookingPage: selectedEmployee = ${widget.selectedEmployee?.userId ?? "NULL"}');

    // Provider üzerinden yükleme yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppointmentProvider>();
      provider.loadBranch(widget.barberId, initialBranch: widget.branch);
      provider.loadBookedSlots(widget.barberId, _selectedDate, userId: widget.selectedEmployee?.userId);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _currentPage == 1) {
      context
          .read<AppointmentProvider>()
          .loadBookedSlots(widget.barberId, _selectedDate, userId: widget.selectedEmployee?.userId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _scrollController.dispose();
    _cardNumberFocusNode.dispose();
    _cardNumberController.dispose();
    _cardExpirationMonthController.dispose();
    _cardExpirationYearController.dispose();
    _cardCvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Kullanıcı swipe yapamasın
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  if (page == 1) {
                    context
                        .read<AppointmentProvider>()
                        .loadBookedSlots(widget.barberId, _selectedDate, userId: widget.selectedEmployee?.userId);
                  }
                },
                children: [
                  _buildDateSelection(),
                  _buildTimeSelection(),
                  _buildPaymentSelection(),
                  _buildConfirmation(),
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
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
              icon: Icon(
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
                  'Randevu Al',
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _getStepTitle(),
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

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
                if (index < _totalSteps - 1)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServicesSummary(),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Tarih Seçin',
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildCalendar(),
        ],
      ),
    );
  }

  Widget _buildTimeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectedDateInfo(),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Müsait Saatler',
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTimeSlots(),
        ],
      ),
    );
  }

  Widget _buildPaymentSelection() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServicesSummary(),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Ödeme Yöntemi',
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Randevunuz için ödeme yönteminizi seçin',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildPaymentOption(
            _paymentMethodCash,
            'Nakit',
            'Salon başında ödeme yapın',
            Icons.payments_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildPaymentOption(
            _paymentMethodCard,
            'Kredi/Banka Kartı',
            'Salon başında kart ile ödeme yapın',
            Icons.credit_card,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildPaymentOption(
            _paymentMethodOnline,
            'Online Ödeme',
            'Online ödeme ile güvenli işlem',
            Icons.payment,
          ),
          const SizedBox(height: AppSpacing.xl),
          // Online ödeme seçildiğinde kart bilgileri formu göster
          if (_selectedPaymentMethod == _paymentMethodOnline)
            Container(
              key: _cardFormKey,
              child: _buildCardForm(),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
        // Online ödeme seçildiğinde kart formuna scroll yap
        if (value == _paymentMethodOnline) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_cardFormKey.currentContext != null) {
              Scrollable.ensureVisible(
                _cardFormKey.currentContext!,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                alignment:
                    0.1, // Kart numarası alanı ekranın üst kısmında görünsün
              );
              // Scroll tamamlandıktan sonra kart numarası alanına odaklan
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted) {
                  _cardNumberFocusNode.requestFocus();
                }
              });
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
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
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: isSelected ? null : Border.all(color: AppColors.border),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kart Bilgileri',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _cardNumberController,
              focusNode: _cardNumberFocusNode,
              decoration: InputDecoration(
                labelText: 'Kart Numarası',
                hintText: '0000 0000 0000 0000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kart numarası zorunludur';
                }
                final cardNumber = value.replaceAll(' ', '');
                if (cardNumber.length < 13 || cardNumber.length > 19) {
                  return 'Geçerli bir kart numarası giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cardExpirationMonthController,
                    decoration: InputDecoration(
                      labelText: 'Ay',
                      hintText: 'MM',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ay zorunludur';
                      }
                      final month = int.tryParse(value);
                      if (month == null || month < 1 || month > 12) {
                        return '01-12 arası';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cardExpirationYearController,
                    decoration: InputDecoration(
                      labelText: 'Yıl',
                      hintText: 'YY',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Yıl zorunludur';
                      }
                      if (value.length != 2) {
                        return '2 haneli yıl';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cardCvcController,
                    decoration: InputDecoration(
                      labelText: 'CVC',
                      hintText: '123',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'CVC zorunludur';
                      }
                      if (value.length < 3 || value.length > 4) {
                        return '3-4 haneli CVC';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border:
                    Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Ödemeniz 3D Secure ile güvence altındadır.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
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

  Widget _buildConfirmation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Randevu Detayları',
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildAppointmentSummary(),
        ],
      ),
    );
  }

  Widget _buildServicesSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: Image.network(
                    widget.barberImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.backgroundSecondary,
                        child: Icon(
                          Icons.person,
                          size: 25,
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.barberName,
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          '₺${widget.totalPrice.toStringAsFixed(0)}',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${widget.totalDuration}m',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Seçilen Hizmetler',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...widget.selectedServices.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      service.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '₺${service.price.toStringAsFixed(0)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.success,
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
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _calendarDaysToShow,
            itemBuilder: (context, index) {
              final date = now.add(Duration(days: index));
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year == _selectedDate.year;
              final isToday = date.day == now.day &&
                  date.month == now.month &&
                  date.year == now.year;
              final isPast =
                  date.isBefore(now.subtract(const Duration(days: 1)));
              final workingHoursForDate = provider.getWorkingHoursForDate(date);
              final isClosedDay = workingHoursForDate == null;

              return Container(
                width: 70,
                margin: const EdgeInsets.only(right: AppSpacing.md),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    onTap: (isPast || isClosedDay)
                        ? null
                        : () {
                            setState(() {
                              _selectedDate = date;
                              _selectedTimeSlot =
                                  null; // Reset time slot on date change
                            });
                            // Tarih değiştiğinde randevuları yeniden yükle
                            provider.loadBookedSlots(widget.barberId, date, userId: widget.selectedEmployee?.userId);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isPast || isClosedDay)
                                ? AppColors.backgroundSecondary
                                    .withValues(alpha: 0.5)
                                : AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isPast || isClosedDay)
                                  ? AppColors.border.withValues(alpha: 0.3)
                                  : AppColors.border,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getDayName(date.weekday),
                            style: AppTypography.bodySmall.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : (isPast || isClosedDay)
                                      ? AppColors.textTertiary
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            date.day.toString(),
                            style: AppTypography.h6.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : (isPast || isClosedDay)
                                      ? AppColors.textTertiary
                                      : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isClosedDay) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Kapalı',
                              style: AppTypography.caption.copyWith(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else if (isToday) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedDateInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seçilen Tarih',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatSelectedDate(),
                  style: AppTypography.h6.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingBookedSlots) {
          return const Center(child: CircularProgressIndicator());
        }

        final is24Hours = provider.branch?.workingHours['all'] == '7/24 Açık';
        final availableTimeSlots =
            provider.getAvailableTimeSlots(_selectedDate, is24Hours: is24Hours);

        if (availableTimeSlots.isEmpty) {
          return Center(
            child: Text(
              'Bu tarih için uygun saat bulunmamaktadır.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: availableTimeSlots.length,
          itemBuilder: (context, index) {
            final timeSlot = availableTimeSlots[index];
            final isSelected = _selectedTimeSlot == timeSlot;

            final isBooked = provider.isSlotBooked(timeSlot);
            final isPastTime = provider.isPastTime(timeSlot, _selectedDate);
            final isOutsideWorkingHours =
                provider.isOutsideWorkingHours(timeSlot, _selectedDate);
            final isAvailableForDuration = provider.isSlotAvailableForDuration(
                timeSlot, widget.totalDuration, _selectedDate);

            // Dolu veya uygun olmayan slotları disable et
            final bool isDisabled = isBooked ||
                isPastTime ||
                isOutsideWorkingHours ||
                !isAvailableForDuration;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                onTap: isDisabled
                    ? null
                    : () => setState(() => _selectedTimeSlot = timeSlot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isBooked
                            ? AppColors.error.withValues(
                                alpha:
                                    0.1) // Dolu slotlar için hafif kırmızı arka plan
                            : isDisabled
                                ? AppColors.backgroundSecondary
                                    .withValues(alpha: 0.5)
                                : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : isBooked
                              ? AppColors.error.withValues(
                                  alpha:
                                      0.5) // Dolu slotlar için kırmızı çerçeve
                              : (!isAvailableForDuration)
                                  ? AppColors.warning.withValues(alpha: 0.3)
                                  : (isPastTime || isOutsideWorkingHours)
                                      ? AppColors.border.withValues(alpha: 0.3)
                                      : AppColors.border,
                      width: (isBooked || !isAvailableForDuration) ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: (isBooked || !isAvailableForDuration)
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                timeSlot,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isBooked
                                      ? AppColors
                                          .error // Dolu saatler için kırmızı yazı
                                      : isSelected
                                          ? Colors.white
                                          : (isPastTime ||
                                                  isOutsideWorkingHours)
                                              ? AppColors.textTertiary
                                              : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                isBooked ? 'Dolu' : 'Yetersiz',
                                style: AppTypography.caption.copyWith(
                                  color: isBooked
                                      ? AppColors.error
                                      : AppColors.textTertiary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            timeSlot,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : (isPastTime || isOutsideWorkingHours)
                                      ? AppColors.textTertiary
                                      : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppointmentSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('İşletme', widget.barberName),
          const SizedBox(height: AppSpacing.md),
          if (widget.selectedEmployee != null) ...[
            _buildSummaryRow(
                'Çalışan', widget.selectedEmployee!.userDetail.fullName),
            const SizedBox(height: AppSpacing.md),
          ],
          _buildSummaryRow('Tarih', _formatSelectedDate()),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryRow('Saat', _selectedTimeSlot ?? 'Seçilmedi'),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryRow('Süre', '${widget.totalDuration} dakika'),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryRow(
            'Toplam Fiyat',
            '₺${widget.totalPrice.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: AppSpacing.lg,
            bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (_currentPage > 0) ...[
                Expanded(
                  child: PremiumButton(
                    text: 'Geri',
                    onPressed: provider.isCreatingAppointment
                        ? null
                        : _goToPreviousPage,
                    variant: ButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
              ],
              Expanded(
                flex: _currentPage > 0 ? 1 : 1,
                child: PremiumButton(
                  text: _getButtonText(),
                  onPressed: provider.isCreatingAppointment
                      ? null
                      : (_canContinue() ? _handleContinue : null),
                  variant: ButtonVariant.primary,
                  isLoading: provider.isCreatingAppointment,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStepTitle() {
    switch (_currentPage) {
      case 0:
        return 'Tercih ettiğiniz tarihi seçin';
      case 1:
        return 'Müsait zaman dilimini seçin';
      case 2:
        return 'Ödeme yönteminizi seçin';
      case 3:
        return 'Randevu detaylarınızı gözden geçirin';
      default:
        return '';
    }
  }

  String _getButtonText() {
    return _currentPage == _totalSteps - 1 ? 'Randevu Al' : 'Devam Et';
  }

  bool _canContinue() {
    switch (_currentPage) {
      case 0:
        return true;
      case 1:
        return _selectedTimeSlot != null;
      case 2:
        return true;
      case 3:
        return _selectedTimeSlot != null;
      default:
        return false;
    }
  }

  void _handleContinue() {
    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    if (_currentPage < _totalSteps - 1) {
      // Online ödeme seçildiyse ve ödeme sayfasındaysak, kart bilgilerini kontrol et
      if (_currentPage == 2 && _selectedPaymentMethod == _paymentMethodOnline) {
        if (_formKey.currentState?.validate() ?? false) {
          _goToNextPage();
        }
      } else {
        _goToNextPage();
      }
    } else {
      _bookAppointment();
    }
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _bookAppointment() async {
    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    final provider = context.read<AppointmentProvider>();

    // UI tarafındaki son kontroller (gerekirse)
    if (_selectedTimeSlot == null) return;

    await provider.createAppointment(
      barberId: widget.barberId,
      selectedDate: _selectedDate,
      selectedTimeSlot: _selectedTimeSlot!,
      selectedServices: widget.selectedServices,
      userId: widget.selectedEmployee?.userId, // Pass selected user ID
      paidType: _selectedPaymentMethod,
      // Online ödeme seçildiyse kart bilgileri gönderilir
      // cash ve creditCard fiziki mağazada ödeme için, kart bilgileri gönderilmiyor
      cardNumber: _selectedPaymentMethod == _paymentMethodOnline
          ? _cardNumberController.text.replaceAll(' ', '')
          : null,
      cardExpirationMonth: _selectedPaymentMethod == _paymentMethodOnline
          ? _cardExpirationMonthController.text.padLeft(2, '0')
          : null,
      cardExpirationYear: _selectedPaymentMethod == _paymentMethodOnline
          ? _cardExpirationYearController.text
          : null,
      cardCvc: _selectedPaymentMethod == _paymentMethodOnline
          ? _cardCvcController.text
          : null,
      onSuccess: (htmlContent) async {
        // Online ödeme seçildiyse ve HTML içerik döndüyse, ödeme sayfasına yönlendir
        if (_selectedPaymentMethod == 'online' &&
            htmlContent != null &&
            htmlContent.isNotEmpty) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PaymentWebViewPage(htmlContent: htmlContent),
            ),
          );

          // Debug log
          print('AppointmentBookingPage: WebView\'dan dönen result: $result');

          // Ödeme tamamlandıysa onay sayfasına git
          if (result == true && mounted) {
            // Ödeme başarılı - onay sayfasına git
            // Tüm navigation stack'i temizle ve onay sayfasına git (hizmet seçim sayfasına geri dönülmesin)
            print(
                'AppointmentBookingPage: Ödeme başarılı, onay sayfasına yönlendiriliyor');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => BookingConfirmationPage(
                  barberId: widget.barberId,
                  barberName: widget.barberName,
                  selectedDate: _selectedDate,
                  selectedTimeSlot: _selectedTimeSlot!,
                  selectedServices: widget.selectedServices,
                  totalPrice: widget.totalPrice,
                  totalDuration: widget.totalDuration,
                  paymentMethod: _selectedPaymentMethod,
                ),
              ),
              (route) => false, // Tüm önceki sayfaları kaldır
            );
          } else if (result == false && mounted) {
            print(
                'AppointmentBookingPage: Ödeme başarısız, hata mesajı gösteriliyor');
            // Ödeme başarısız - hata mesajı göster
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                icon:
                    Icon(Icons.error_outline, color: AppColors.error, size: 48),
                title: Text(
                  'Ödeme Başarısız',
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                ),
                content: Text(
                  'Ödeme işlemi tamamlanamadı. Lütfen tekrar deneyin veya farklı bir ödeme yöntemi seçin.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Tamam'),
                  ),
                ],
              ),
            );
          } else if (result == null && mounted) {
            // WebView kapatıldı veya result dönmedi - kullanıcı geri tuşuna basmış olabilir
            // Online ödeme için randevu oluşturuldu ama ödeme tamamlanmadı
            print(
                'AppointmentBookingPage: WebView kapatıldı, result null - ödeme tamamlanmadı');
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                icon: Icon(Icons.info_outline, color: AppColors.info, size: 48),
                title: Text(
                  'Ödeme Tamamlanmadı',
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                ),
                content: Text(
                  'Ödeme işlemi tamamlanmadı. Randevunuz oluşturuldu ancak ödeme bekleniyor. Lütfen randevu detaylarınızı kontrol edin.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Dialog'u kapat
                      // Randevu oluşturuldu ama ödeme tamamlanmadı - kullanıcıyı geri gönder
                      Navigator.pop(context); // AppointmentBookingPage'den çık
                    },
                    child: Text('Tamam'),
                  ),
                ],
              ),
            );
          }
        } else if (_selectedPaymentMethod == 'online' &&
            (htmlContent == null || htmlContent.isEmpty)) {
          // Online seçildi ama HTML içerik dönmedi - hata mesajı göster
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              icon: Icon(Icons.error_outline, color: AppColors.error, size: 48),
              title: Text(
                'Ödeme Hatası',
                style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
              ),
              content: Text(
                'Online ödeme sayfası yüklenemedi. Lütfen tekrar deneyin veya farklı bir ödeme yöntemi seçin.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tamam'),
                ),
              ],
            ),
          );
        } else {
          // cash veya creditCard seçildiyse - onay sayfasına git
          // Tüm navigation stack'i temizle (hizmet seçim sayfasına geri dönülmesin)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => BookingConfirmationPage(
                barberId: widget.barberId,
                barberName: widget.barberName,
                selectedDate: _selectedDate,
                selectedTimeSlot: _selectedTimeSlot!,
                selectedServices: widget.selectedServices,
                totalPrice: widget.totalPrice,
                totalDuration: widget.totalDuration,
                paymentMethod: _selectedPaymentMethod,
              ),
            ),
            (route) => false, // Tüm önceki sayfaları kaldır
          );
        }
      },
      onError: (error) {
        // Eğer hata "zaten randevu var" içeriyorsa, o saati bloke et
        if (error.toLowerCase().contains('zaten randevu var') ||
            error.toLowerCase().contains('dolu') ||
            error.toLowerCase().contains('uygun olan en erken')) {
          provider.markSlotAsUnavailable(_selectedTimeSlot!);

          // Seçimi kaldır
          setState(() {
            _selectedTimeSlot = null;
          });
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            icon: Icon(Icons.error_outline, color: AppColors.error, size: 48),
            title: Text(
              'Randevu Oluşturulamadı',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
            ),
            content: Text(
              error,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tamam'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Pzt';
      case 2:
        return 'Sal';
      case 3:
        return 'Çar';
      case 4:
        return 'Per';
      case 5:
        return 'Cum';
      case 6:
        return 'Cmt';
      case 7:
        return 'Paz';
      default:
        return '';
    }
  }

  String _formatSelectedDate() {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';
  }
}
