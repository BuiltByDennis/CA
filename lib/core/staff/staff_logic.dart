import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

// Multi-staff logic (Phase 4) — pure permission matrix + PIN hashing.
///
// Roles on a seller's device:
//  - owner: everything (the account holder)
//  - manager: issue + capture + analytics + verification view/submit; no staff mgmt, no key export
//  - cashier: issue + capture + history; NO analytics, NO verification, NO staff
//  - accountant: analytics + history + export; cannot issue
// Enforcement is device-level (this device, this business). Server-enforced
// per-person accounts arrive with phone-OTP account linking in a later phase.

const roleOwner = 'owner';
const roleManager = 'manager';
const roleCashier = 'cashier';
const roleAccountant = 'accountant';

bool canIssue(String role) =>
    role == roleOwner || role == roleManager || role == roleCashier;
bool canCapture(String role) => canIssue(role);
bool canViewAnalytics(String role) =>
    role == roleOwner || role == roleManager || role == roleAccountant;
bool canManageVerification(String role) =>
    role == roleOwner || role == roleManager;
bool canManageStaff(String role) => role == roleOwner;
bool canExportKey(String role) => role == roleOwner;
bool canViewHistory(String role) => true; // every staff role can see history

String roleLabel(String role) => switch (role) {
      roleOwner => 'Owner',
      roleManager => 'Manager',
      roleCashier => 'Cashier',
      roleAccountant => 'Accountant',
      _ => role,
    };

String newPinSalt() =>
    List.generate(16, (_) => Random.secure().nextInt(256)).join('-');

Future<String> hashPin(String pin, String salt) async {
  final h = await Sha256().hash(utf8.encode('$salt:$pin'));
  return base64Url.encode(h.bytes);
}

Future<bool> verifyPin(String pin, String salt, String expectedHash) async =>
    await hashPin(pin, salt) == expectedHash;
