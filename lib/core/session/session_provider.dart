import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../storage/models/shift_record.dart';

enum StaffRole { assistant, supervisor }

class Staff {
  final String id;
  final String name;
  final StaffRole role;

  /// Hash these in anything beyond a proof of concept.
  final String pin;

  const Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.pin,
  });
}

/// Who is at the till, what they are allowed to see, and whether a supervisor
/// has unlocked the privileged views.
///
/// Policy, as agreed:
///  * one app; supervisor extras appear after a PIN entered on this device
///  * assistants never see takings, cost, margin, stock value or other staff's
///    sales
///  * privilege drops the moment a new ordinary sale starts, so an unlocked
///    till is never handed over
///  * a supervisor who wants to sell WITH cost visible starts a supervisor sale
class SessionProvider extends ChangeNotifier {
  SessionProvider({required this.shifts, required this.staff});

  final Box<ShiftRecord> shifts;
  final List<Staff> staff;

  Staff? _signedIn;
  bool _supervisorUnlocked = false;
  DateTime? _unlockedAt;
  bool _supervisorSaleMode = false;
  String? _openShiftId;

  Staff? get signedIn => _signedIn;
  bool get isSignedIn => _signedIn != null;

  /// True when privileged data may be rendered.
  bool get canSeeMoney =>
      _signedIn?.role == StaffRole.supervisor && _supervisorUnlocked;

  bool get supervisorUnlocked => _supervisorUnlocked;
  DateTime? get unlockedAt => _unlockedAt;
  bool get supervisorSaleMode => _supervisorSaleMode;

  /// The header line that tells you which mode you are in.
  String get modeLine {
    if (_signedIn == null) return 'Not signed in';
    if (_supervisorSaleMode) return 'Supervisor · cost visible';
    if (canSeeMoney) {
      final t = _unlockedAt!;
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return 'Supervisor · unlocked $hh:$mm';
    }
    return '${_signedIn!.name} · Till 1';
  }

  ShiftRecord? get openShift =>
      _openShiftId == null ? null : shifts.get(_openShiftId!);

  bool signIn(String staffId, String pin) {
    final match = staff.firstWhere(
      (s) => s.id == staffId && s.pin == pin,
      orElse: () => const Staff(id: '', name: '', role: StaffRole.assistant, pin: ''),
    );
    if (match.id.isEmpty) return false;
    _signedIn = match;
    _supervisorUnlocked = false;
    _supervisorSaleMode = false;
    notifyListeners();
    return true;
  }

  void signOut() {
    _signedIn = null;
    _supervisorUnlocked = false;
    _supervisorSaleMode = false;
    notifyListeners();
  }

  /// Tapping the padlock. Any supervisor's PIN unlocks, so a supervisor can
  /// authorise on an assistant's till without signing them out.
  bool unlockSupervisor(String pin) {
    final sup = staff.firstWhere(
      (s) => s.role == StaffRole.supervisor && s.pin == pin,
      orElse: () => const Staff(id: '', name: '', role: StaffRole.assistant, pin: ''),
    );
    if (sup.id.isEmpty) return false;
    _signedIn = sup;
    _supervisorUnlocked = true;
    _unlockedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  void lock() {
    _supervisorUnlocked = false;
    _supervisorSaleMode = false;
    _unlockedAt = null;
    notifyListeners();
  }

  /// Call from SalesProvider when a cart is started. An ordinary sale relocks;
  /// an explicit supervisor sale keeps cost visible for that sale only.
  void onSaleStarted({bool supervisorSale = false}) {
    if (supervisorSale && canSeeMoney) {
      _supervisorSaleMode = true;
    } else {
      _supervisorUnlocked = false;
      _supervisorSaleMode = false;
      _unlockedAt = null;
    }
    notifyListeners();
  }

  void onSaleFinished() {
    if (_supervisorSaleMode) {
      _supervisorSaleMode = false;
      notifyListeners();
    }
  }

  // ---- Shift lifecycle -----------------------------------------------------

  ShiftRecord openShiftWithFloat(double floatUsd) {
    final record = ShiftRecord(
      id: 'shift-${DateTime.now().millisecondsSinceEpoch}',
      staffId: _signedIn?.id ?? 'unknown',
      staffName: _signedIn?.name ?? 'Unknown',
      openedAt: DateTime.now(),
      openingFloat: floatUsd,
    );
    shifts.put(record.id, record);
    _openShiftId = record.id;
    notifyListeners();
    return record;
  }

  /// The assistant counts and sees their own variance; the cross-shift pattern
  /// is written to the AI actions log for the supervisor instead.
  ShiftRecord? closeShift({
    required double countedCash,
    double? countedCashZwl,
    required double expectedCash,
    double? mobileMoneyTotal,
    double? cardTotal,
    String? note,
  }) {
    final current = openShift;
    if (current == null) return null;
    final closed = current.copyWith(
      closedAt: DateTime.now(),
      countedCash: countedCash,
      countedCashZwl: countedCashZwl,
      expectedCash: expectedCash,
      mobileMoneyTotal: mobileMoneyTotal,
      cardTotal: cardTotal,
      closingNote: note,
    );
    shifts.put(closed.id, closed);
    _openShiftId = null;
    notifyListeners();
    return closed;
  }
}
