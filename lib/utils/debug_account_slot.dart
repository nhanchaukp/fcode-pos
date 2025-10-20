import 'package:fcode_pos/services/account_slot_service.dart';
import 'package:flutter/material.dart';

/// Debug utility to test AccountSlotService.available()
///
/// Usage: Add a button in your UI to call this function
/// It will print detailed information about the API response
Future<void> debugAccountSlotService() async {
  final service = AccountSlotService();

  debugPrint('=== Testing AccountSlotService.available() ===');

  try {
    final slots = await service.available();

    debugPrint('✅ Success! Received ${slots.length} slots');

    if (slots.isEmpty) {
      debugPrint('⚠️ WARNING: No slots returned from API');
      return;
    }

    // Print details of first 3 slots
    final displayCount = slots.length > 3 ? 3 : slots.length;
    debugPrint('\nShowing first $displayCount slots:');

    for (var i = 0; i < displayCount; i++) {
      final slot = slots[i];
      debugPrint('\n--- Slot ${i + 1} ---');
      debugPrint('ID: ${slot.id}');
      debugPrint('Name: ${slot.name}');
      debugPrint('Is Active: ${slot.isActive}');
      debugPrint('Account Master ID: ${slot.accountMasterId}');

      if (slot.accountMaster != null) {
        debugPrint('Account Master:');
        debugPrint('  - Name: ${slot.accountMaster!.name}');
        debugPrint('  - Username: ${slot.accountMaster!.username}');
        debugPrint('  - Service Type: ${slot.accountMaster!.serviceType}');
      } else {
        debugPrint('⚠️ Account Master: NULL');
      }

      if (slot.expiryDate != null) {
        final daysUntilExpiry =
            slot.expiryDate!.difference(DateTime.now()).inDays;
        debugPrint('Expiry Date: ${slot.expiryDate}');
        debugPrint('Days until expiry: $daysUntilExpiry');
      } else {
        debugPrint('Expiry Date: NULL');
      }
    }

    // Check if all slots are active
    final inactiveSlots = slots.where((s) => !s.isActive).toList();
    if (inactiveSlots.isNotEmpty) {
      debugPrint('\n⚠️ WARNING: ${inactiveSlots.length} inactive slots found!');
      debugPrint(
          'Inactive slot IDs: ${inactiveSlots.map((s) => s.id).join(', ')}');
    }

    // Check if all slots have account master
    final slotsWithoutMaster =
        slots.where((s) => s.accountMaster == null).toList();
    if (slotsWithoutMaster.isNotEmpty) {
      debugPrint(
          '\n⚠️ WARNING: ${slotsWithoutMaster.length} slots without AccountMaster!');
      debugPrint(
          'Slot IDs without master: ${slotsWithoutMaster.map((s) => s.id).join(', ')}');
    }

    debugPrint('\n=== Test Complete ===');
  } catch (e, stackTrace) {
    debugPrint('❌ ERROR: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

/// Test the list() method as well
Future<void> debugAccountSlotServiceList() async {
  final service = AccountSlotService();

  debugPrint('=== Testing AccountSlotService.list() ===');

  try {
    final slots = await service.list();

    debugPrint('✅ Success! Received ${slots.length} slots');

    final activeSlots = slots.where((s) => s.isActive).toList();
    final inactiveSlots = slots.where((s) => !s.isActive).toList();

    debugPrint('Active slots: ${activeSlots.length}');
    debugPrint('Inactive slots: ${inactiveSlots.length}');
  } catch (e) {
    debugPrint('❌ ERROR: $e');
  }
}
