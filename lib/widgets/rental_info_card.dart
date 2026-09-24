import 'package:flutter/material.dart';
import '../main.dart';
import '../services/app_localizations.dart';

/// Shared "rented item" card used in My Purchases (buyer) and My Sales (seller).
class RentalInfoCard extends StatelessWidget {
  final Map<String, dynamic> rental;
  final String? createdAt;

  const RentalInfoCard({super.key, required this.rental, this.createdAt});

  int _unitDays(String unit) {
    switch (unit) {
      case 'week':
        return 7;
      case 'month':
        return 30;
      default:
        return 1;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final quantity = (rental['quantity'] as num?)?.toInt() ?? 0;
    final unit = '${rental['unit'] ?? 'day'}';
    final daysRemaining = (rental['daysRemaining'] as num?)?.toInt() ?? 0;
    final expired = rental['expired'] == true;
    // The exact end date isn't sent by the server, only "days remaining", so this is an
    // estimate from quantity x unit length (week ~7 days, month ~30 days).
    final totalDays = quantity * _unitDays(unit);

    DateTime? start;
    DateTime? end;
    if (createdAt != null) {
      try {
        start = DateTime.parse(createdAt!).toLocal();
        end = start.add(Duration(days: totalDays));
      } catch (_) {}
    }

    final progress = totalDays > 0
        ? ((totalDays - daysRemaining) / totalDays).clamp(0.0, 1.0)
        : (expired ? 1.0 : 0.0);
    final accent = expired ? Colors.redAccent : AppColors.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: accent.withOpacity(0.15),
                child: Icon(Icons.calendar_month, size: 15, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${AppLocalizations.t('buyer_rented_for')} $quantity $unit${quantity == 1 ? '' : 's'}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  expired ? 'Ended' : '$daysRemaining ${AppLocalizations.t('days_remaining_suffix')}',
                  style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (start != null && end != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Started ${_fmtDate(start)}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                Text('Ends ${_fmtDate(end)}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.fieldFill,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ] else if (expired)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(AppLocalizations.t('rental_ended_remind'), style: TextStyle(color: accent, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
