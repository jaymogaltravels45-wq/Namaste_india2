import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/phone_login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/role_select_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/customer/screens/customer_booking_screen.dart';
import '../../features/customer/screens/customer_booking_detail_screen.dart';
import '../../features/customer/screens/customer_booking_history_screen.dart';
import '../../features/customer/screens/customer_wallet_screen.dart';
import '../../features/customer/screens/customer_profile_screen.dart';
import '../../features/customer/screens/customer_sos_screen.dart';
import '../../features/customer/screens/customer_support_screen.dart';
import '../../features/customer/screens/customer_settings_screen.dart';
import '../../features/customer/screens/customer_offers_screen.dart';
import '../../features/customer/screens/customer_trip_tracking_screen.dart';
import '../../features/customer/screens/customer_notifications_screen.dart';
import '../../features/customer/screens/available_cars_screen.dart';
import '../../features/driver/screens/driver_home_screen.dart';
import '../../features/driver/screens/driver_new_requests_screen.dart';
import '../../features/driver/screens/driver_bid_detail_screen.dart';
import '../../features/driver/screens/driver_booking_detail_screen.dart';
import '../../features/driver/screens/driver_kyc_screen.dart';
import '../../features/driver/screens/driver_profile_screen.dart';
import '../../features/driver/screens/driver_wallet_screen.dart';
import '../../features/driver/screens/add_money_screen.dart';
import '../../features/driver/screens/driver_subscription_screen.dart';
import '../../features/driver/screens/driver_earnings_screen.dart';
import '../../features/driver/screens/driver_requirements_screen.dart';
import '../../features/driver/screens/post_requirement_screen.dart';
import '../../features/driver/screens/driver_offers_screen.dart';
import '../../features/driver/screens/driver_support_screen.dart';
import '../../features/driver/screens/driver_settings_screen.dart';
import '../../features/driver/screens/driver_notifications_screen.dart';
import '../../features/admin/screens/admin_login_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_drivers_screen.dart';
import '../../features/admin/screens/admin_kyc_screen.dart';
import '../../features/admin/screens/admin_bookings_screen.dart';
import '../../features/admin/screens/admin_fares_screen.dart';
import '../../features/admin/screens/admin_wallets_screen.dart';
import '../../features/admin/screens/admin_penalties_screen.dart';
import '../../features/admin/screens/admin_subscriptions_screen.dart';
import '../../features/admin/screens/admin_support_screen.dart';
import '../../features/admin/screens/admin_cms_screen.dart';
import '../../features/admin/screens/admin_analytics_screen.dart';
import '../../features/admin/screens/admin_notifications_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/booking/screens/ride_otp_screen.dart';
import '../../features/booking/screens/payment_screen.dart';
import '../../features/booking/screens/rating_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    errorBuilder: (_, s) => Scaffold(body: Center(child: Text('Not found: ' + s.uri.toString()))),
    routes: [
      GoRoute(path: '/',        builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/role',    builder: (_, __) => const RoleSelectScreen()),
      GoRoute(path: '/setup',   builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/login',   builder: (_, s) {
        final m = s.extra as Map? ?? {};
        return PhoneLoginScreen(role: m['role']?.toString() ?? 'customer');
      }),
      GoRoute(path: '/otp', builder: (_, s) {
        final m = s.extra as Map? ?? {};
        return OtpScreen(phone: m['phone']?.toString() ?? '', role: m['role']?.toString() ?? 'customer', reqId: m['reqId']?.toString() ?? '');
      }),
      GoRoute(path: '/customer',           builder: (_, __) => const CustomerHomeScreen()),
      GoRoute(path: '/customer/booking',   builder: (_, s) => CustomerBookingScreen(type: (s.extra as Map?)?['type']?.toString(), vehicleType: (s.extra as Map?)?['vehicleType']?.toString())),
      GoRoute(path: '/customer/booking/:id', builder: (_, s) => CustomerBookingDetailScreen(bookingId: s.pathParameters['id']!)),
      GoRoute(path: '/customer/history',   builder: (_, __) => const CustomerBookingHistoryScreen()),
      GoRoute(path: '/customer/wallet',    builder: (_, __) => const CustomerWalletScreen()),
      GoRoute(path: '/customer/profile',   builder: (_, __) => const CustomerProfileScreen()),
      GoRoute(path: '/customer/sos',       builder: (_, __) => const CustomerSosScreen()),
      GoRoute(path: '/customer/support',   builder: (_, __) => const CustomerSupportScreen()),
      GoRoute(path: '/customer/settings',  builder: (_, __) => const CustomerSettingsScreen()),
      GoRoute(path: '/customer/offers',    builder: (_, __) => const CustomerOffersScreen()),
      GoRoute(path: '/customer/notifications', builder: (_, __) => const CustomerNotificationsScreen()),
      GoRoute(path: '/customer/tracking/:id', builder: (_, s) => CustomerTripTrackingScreen(bookingId: s.pathParameters['id']!)),
      GoRoute(path: '/customer/cars', builder: (_, __) => const AvailableCarsScreen()),
      GoRoute(path: '/driver',             builder: (_, __) => const DriverHomeScreen()),
      GoRoute(path: '/driver/requests',    builder: (_, __) => const DriverNewRequestsScreen()),
      GoRoute(path: '/driver/bid/:id',     builder: (_, s) => DriverBidDetailScreen(bookingId: s.pathParameters['id']!)),
      GoRoute(path: '/driver/my-booking/:id', builder: (_, s) => DriverBookingDetailScreen(bookingId: s.pathParameters['id']!)),
      GoRoute(path: '/driver/kyc',         builder: (_, __) => const DriverKycScreen()),
      GoRoute(path: '/driver/profile',     builder: (_, __) => const DriverProfileScreen()),
      GoRoute(path: '/driver/wallet',      builder: (_, __) => const DriverWalletScreen()),
      GoRoute(path: '/driver/add-money',   builder: (_, __) => const AddMoneyScreen()),
      GoRoute(path: '/driver/subscription',builder: (_, __) => const DriverSubscriptionScreen()),
      GoRoute(path: '/driver/earnings',    builder: (_, __) => const DriverEarningsScreen()),
      GoRoute(path: '/driver/requirements',builder: (_, __) => const DriverRequirementsScreen()),
      GoRoute(path: '/driver/requirements/post', builder: (_, __) => const PostRequirementScreen()),
      GoRoute(path: '/driver/offers/:id',  builder: (_, s) => DriverOffersScreen(bookingId: s.pathParameters['id']!)),
      GoRoute(path: '/driver/support',     builder: (_, __) => const DriverSupportScreen()),
      GoRoute(path: '/driver/settings',    builder: (_, __) => const DriverSettingsScreen()),
      GoRoute(path: '/driver/notifications', builder: (_, __) => const DriverNotificationsScreen()),
      GoRoute(path: '/admin',              builder: (_, __) => const AdminLoginScreen()),
      GoRoute(path: '/admin/dashboard',    builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/users',        builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: '/admin/drivers',      builder: (_, __) => const AdminDriversScreen()),
      GoRoute(path: '/admin/kyc',          builder: (_, __) => const AdminKycScreen()),
      GoRoute(path: '/admin/bookings',     builder: (_, __) => const AdminBookingsScreen()),
      GoRoute(path: '/admin/fares',        builder: (_, __) => const AdminFaresScreen()),
      GoRoute(path: '/admin/wallets',      builder: (_, __) => const AdminWalletsScreen()),
      GoRoute(path: '/admin/penalties',    builder: (_, __) => const AdminPenaltiesScreen()),
      GoRoute(path: '/admin/subscriptions',builder: (_, __) => const AdminSubscriptionsScreen()),
      GoRoute(path: '/admin/support',      builder: (_, __) => const AdminSupportScreen()),
      GoRoute(path: '/admin/cms',          builder: (_, __) => const AdminCmsScreen()),
      GoRoute(path: '/admin/analytics',    builder: (_, __) => const AdminAnalyticsScreen()),
      GoRoute(path: '/admin/notifications',builder: (_, __) => const AdminNotificationsScreen()),
      GoRoute(path: '/admin/settings',     builder: (_, __) => const AdminSettingsScreen()),
      GoRoute(path: '/ride-otp/:id',       builder: (_, s) => RideOtpScreen(bookingId: s.pathParameters['id']!)),
      GoRoute(path: '/payment/:id',        builder: (_, s) => PaymentScreen(bookingId: s.pathParameters['id']!)),
      GoRoute(path: '/rating/:id',         builder: (_, s) => RatingScreen(bookingId: s.pathParameters['id']!)),
    ],
  );
}
