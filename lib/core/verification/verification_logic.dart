/// Business verification — pure validation logic (Phase 3), unit-tested.
///
/// Required to submit:
///  - legal + trading name, business type, address, category, contact phone
///  - ORC number for limited/company; Ghana Card for sole_prop/informal owners
///  - TIN if the business says it has one / is VAT-registered
///  - at least one document: ORC certificate (companies), Ghana Card (sole
///    prop/informal), or business permit; TIN certificate when TIN is given
library;

class VerificationForm {
  const VerificationForm({
    required this.legalName,
    required this.tradingName,
    required this.businessType,
    this.orcNumber,
    this.tin,
    this.vatRegistered = false,
    this.address,
    this.category,
    this.contactPhone,
    this.contactEmail,
    this.ghanaCardNo,
    this.docTypes = const [],
  });
  final String legalName;
  final String tradingName;
  final String businessType;
  final String? orcNumber;
  final String? tin;
  final bool vatRegistered;
  final String? address;
  final String? category;
  final String? contactPhone;
  final String? contactEmail;
  final String? ghanaCardNo;
  final List<String> docTypes;

  bool get isCompany => businessType == 'limited' || businessType == 'company';
  bool get isIndividual => businessType == 'sole_prop' || businessType == 'informal';
}

List<String> validateVerification(VerificationForm f) {
  final errors = <String>[];
  bool blank(String? s) => s == null || s.trim().isEmpty;
  if (blank(f.legalName)) errors.add('Legal business name is required.');
  if (blank(f.tradingName)) errors.add('Trading name is required.');
  if (blank(f.address)) errors.add('Business address/location is required.');
  if (blank(f.category)) errors.add('Business category is required.');
  if (blank(f.contactPhone)) errors.add('Contact phone is required.');
  if (f.isCompany && blank(f.orcNumber)) {
    errors.add('ORC registration number is required for a limited/company.');
  }
  if (f.isIndividual && blank(f.ghanaCardNo)) {
    errors.add('Owner Ghana Card number is required for sole proprietors/informal sellers.');
  }
  if (f.vatRegistered && blank(f.tin)) {
    errors.add('TIN is required when VAT-registered.');
  }
  if (f.docTypes.isEmpty) {
    errors.add('Attach at least one document (certificate, Ghana Card, or permit).');
  }
  if (f.isCompany && !f.docTypes.contains('orc_certificate')) {
    errors.add('Attach the ORC certificate.');
  }
  if (f.isIndividual && !f.docTypes.contains('ghana_card')) {
    errors.add('Attach a photo of the owner Ghana Card.');
  }
  if (!blank(f.tin) && !f.docTypes.contains('tin_certificate')) {
    errors.add('Attach the TIN certificate for the TIN provided.');
  }
  return errors;
}

/// Human label + guidance for each verification status.
String verificationStatusMessage(String status, String? note) => switch (status) {
      'verified' => 'Your business is verified. Buyers see the Verified badge for your receipts.',
      'pending' => 'Submitted — waiting for review. You can keep selling; the badge appears once approved.',
      'rejected' => 'Not approved${note != null && note.isNotEmpty ? ': $note' : ''}. Fix and resubmit.',
      _ => 'Not submitted yet. Verify to earn the Verified badge buyers trust.',
    };
