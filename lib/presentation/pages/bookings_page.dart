import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../widgets/booking_card.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTypography.bodyMedium,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingBookings(),
          _buildCompletedBookings(),
          _buildCancelledBookings(),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: 3,
      separatorBuilder:
          (context, index) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        return BookingCard(
          salonName: _getUpcomingSalonName(index),
          service: _getUpcomingService(index),
          date: _getUpcomingDate(index),
          time: _getUpcomingTime(index),
          price: _getUpcomingPrice(index),
          status: BookingStatus.upcoming,
          onCancel: () => _showCancelDialog(context),
          onReschedule: () => _showRescheduleDialog(context),
        );
      },
    );
  }

  Widget _buildCompletedBookings() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: 5,
      separatorBuilder:
          (context, index) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        return BookingCard(
          salonName: _getCompletedSalonName(index),
          service: _getCompletedService(index),
          date: _getCompletedDate(index),
          time: _getCompletedTime(index),
          price: _getCompletedPrice(index),
          status: BookingStatus.completed,
          onReview: () => _showReviewDialog(context),
        );
      },
    );
  }

  Widget _buildCancelledBookings() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: 2,
      separatorBuilder:
          (context, index) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        return BookingCard(
          salonName: _getCancelledSalonName(index),
          service: _getCancelledService(index),
          date: _getCancelledDate(index),
          time: _getCancelledTime(index),
          price: _getCancelledPrice(index),
          status: BookingStatus.cancelled,
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Cancel Booking',
              style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
            ),
            content: Text(
              'Are you sure you want to cancel this booking?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Keep Booking',
                  style: AppTypography.buttonMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: Text(
                  'Cancel Booking',
                  style: AppTypography.buttonMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showRescheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Reschedule Booking',
              style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
            ),
            content: Text(
              'This will redirect you to select a new date and time.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTypography.buttonMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Reschedule',
                  style: AppTypography.buttonMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Leave a Review',
              style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
            ),
            content: Text(
              'How was your experience? Your feedback helps other users.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Skip',
                  style: AppTypography.buttonMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Write Review',
                  style: AppTypography.buttonMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // TODO: Replace with real data methods from API
  String _getUpcomingSalonName(int index) {
    // TODO: Get from API
    return '';
  }

  String _getUpcomingService(int index) {
    // TODO: Get from API
    return '';
  }

  String _getUpcomingDate(int index) {
    // TODO: Get from API
    return '';
  }

  String _getUpcomingTime(int index) {
    // TODO: Get from API
    return '';
  }

  String _getUpcomingPrice(int index) {
    // TODO: Get from API
    return '';
  }

  String _getCompletedSalonName(int index) {
    // TODO: Get from API
    return '';
  }

  String _getCompletedService(int index) {
    // TODO: Get from API
    return '';
  }

  String _getCompletedDate(int index) {
    // TODO: Get from API
    return '';
  }

  String _getCompletedTime(int index) {
    // TODO: Get from API
    return '';
  }

  String _getCompletedPrice(int index) {
    // TODO: Get from API
    return '';
  }

  String _getCancelledSalonName(int index) {
    // TODO: Get from API
    return '';
  }

  String _getCancelledService(int index) {
    // TODO: Get from API
    return '';
  }

  String _getCancelledDate(int index) {
    // TODO: Get from API
    return '';
  }

  String _getCancelledTime(int index) {
    // TODO: Get from API
    return '';
  }

  String _getCancelledPrice(int index) {
    // TODO: Get from API
    return '';
  }
}
