import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:worker_app/models/job.dart';
import 'package:worker_app/models/welfare_transaction.dart';
import 'package:worker_app/models/worker_profile.dart';
import 'package:worker_app/theme/app_colors.dart';
import 'package:worker_app/utils/formatting.dart';
import 'package:worker_app/widgets/status_chip.dart';
import 'package:worker_app/widgets/count_up_text.dart';
import 'package:worker_app/services/mock_data_service.dart';

void main() {
  group('Contract model parsing', () {
    test('Job parses Socket.IO job_offer payload (flat lat/lng, 5%)', () {
      final job = Job.fromJson({
        'booking_id': 'b123',
        'service_type': 'electrician',
        'customer_name': 'Ananya Sharma',
        'price': 500,
        'distance_km': 1.2,
        'address': 'Flat 402, Connaught Place',
        'lat': 28.63,
        'lng': 77.21,
        'expires_at': DateTime.now().add(const Duration(seconds: 60)).toIso8601String(),
      });

      expect(job.bookingId, 'b123');
      expect(job.customerLatitude, 28.63);
      expect(job.customerLongitude, 77.21);
      expect(job.distanceMeters, closeTo(1200, 0.01));
      expect(job.welfareContribution, closeTo(25.0, 0.001)); // exactly 5%
      expect(job.status, JobStatus.pending);
    });

    test('Job maps contract statuses including en_route/arrived/started', () {
      for (final s in ['pending', 'accepted', 'declined', 'en_route',
          'arrived', 'started', 'completed', 'cancelled']) {
        final job = Job.fromJson({'id': 'x', 'status': s, 'price': 100});
        expect(job.status.apiValue, s);
      }
    });

    test('Welfare transaction uses `reason` and contract statuses only', () {
      final tx = WelfareTransaction.fromJson({
        'id': 't1',
        'type': 'claim',
        'amount': 1500,
        'reason': 'OPD eye checkup reimbursement',
        'status': 'pending',
        'created_at': '2026-01-15T10:00:00Z',
      });
      expect(tx.reason, contains('eye checkup'));
      expect(tx.isContribution, isFalse);
      expect(tx.status, WelfareClaimStatus.pending);

      // No `disbursed` status exists — unknown values map to approved.
      final legacy = WelfareTransaction.fromJson(
          {'type': 'contribution', 'status': 'disbursed', 'amount': 5});
      expect(legacy.status, WelfareClaimStatus.approved);
    });

    test('Worker profile reads flat lat/lng + certification', () {
      final p = WorkerProfile.fromJson({
        'id': 'w1',
        'name': 'Ramesh Kumar',
        'phone': '9811100001',
        'skills': ['electrician'],
        'service_type': 'electrician',
        'rating': 4.7,
        'total_jobs': 12,
        'lat': 28.61,
        'lng': 77.21,
        'is_online': false,
        'certification': 'verified',
      });
      expect(p.latitude, 28.61);
      expect(p.longitude, 77.21);
      expect(p.isOnline, isFalse);
      expect(p.certification, 'verified');
    });
  });

  group('Formatting helpers', () {
    test('initialsOf never RangeErrors on empty strings', () {
      expect(initialsOf(''), '?');
      expect(initialsOf('   '), '?');
      expect(initialsOf('Ramesh Kumar'), 'RK');
    });
    test('phone normalization requires 10 digits', () {
      expect(isValidPhone('+91 98111 00001'), isTrue);
      expect(normalizePhone('+91 98111 00001'), '9811100001');
      expect(isValidPhone('12345'), isFalse);
    });
  });

  group('Widgets', () {
    testWidgets('StatusChip renders label for completed status', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatusChip.job(JobStatus.completed)),
      ));
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('CountUpText renders currency value', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CountUpText(value: 1350)),
      ));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.textContaining('₹'), findsOneWidget);
    });
  });

  group('Demo data sanity', () {
    test('demo welfare snapshot matches contract shape & 5% money rule', () {
      final snap = MockDataService.getDemoWelfareSnapshot();
      expect(snap.balance, greaterThan(0));
      expect(snap.transactions, isNotEmpty);
      final offer = MockDataService.getDemoIncomingJob();
      // 450 * 0.05 = 22.5
      expect(offer.welfareContribution,
          closeTo(offer.price * 0.05, 0.001));
    });

    test('palette has no default Material blue', () {
      const materialBlue = Color(0xFF2196F3);
      const palette = [
        AppColors.gold, AppColors.indigo, AppColors.success,
        AppColors.danger, AppColors.info, AppColors.night1,
      ];
      expect(palette.contains(materialBlue), isFalse);
    });
  });
}
