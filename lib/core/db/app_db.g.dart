// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phone,
    mode,
    businessName,
    businessId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      ),
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final String id;
  final String name;
  final String phone;
  final String mode;
  final String? businessName;
  final String? businessId;
  const ProfileRow({
    required this.id,
    required this.name,
    required this.phone,
    required this.mode,
    this.businessName,
    this.businessId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['mode'] = Variable<String>(mode);
    if (!nullToAbsent || businessName != null) {
      map['business_name'] = Variable<String>(businessName);
    }
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      mode: Value(mode),
      businessName: businessName == null && nullToAbsent
          ? const Value.absent()
          : Value(businessName),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      mode: serializer.fromJson<String>(json['mode']),
      businessName: serializer.fromJson<String?>(json['businessName']),
      businessId: serializer.fromJson<String?>(json['businessId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'mode': serializer.toJson<String>(mode),
      'businessName': serializer.toJson<String?>(businessName),
      'businessId': serializer.toJson<String?>(businessId),
    };
  }

  ProfileRow copyWith({
    String? id,
    String? name,
    String? phone,
    String? mode,
    Value<String?> businessName = const Value.absent(),
    Value<String?> businessId = const Value.absent(),
  }) => ProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    mode: mode ?? this.mode,
    businessName: businessName.present ? businessName.value : this.businessName,
    businessId: businessId.present ? businessId.value : this.businessId,
  );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      mode: data.mode.present ? data.mode.value : this.mode,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('mode: $mode, ')
          ..write('businessName: $businessName, ')
          ..write('businessId: $businessId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, phone, mode, businessName, businessId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.mode == this.mode &&
          other.businessName == this.businessName &&
          other.businessId == this.businessId);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> mode;
  final Value<String?> businessName;
  final Value<String?> businessId;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.mode = const Value.absent(),
    this.businessName = const Value.absent(),
    this.businessId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String name,
    required String phone,
    required String mode,
    this.businessName = const Value.absent(),
    this.businessId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       phone = Value(phone),
       mode = Value(mode);
  static Insertable<ProfileRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? mode,
    Expression<String>? businessName,
    Expression<String>? businessId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (mode != null) 'mode': mode,
      if (businessName != null) 'business_name': businessName,
      if (businessId != null) 'business_id': businessId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? phone,
    Value<String>? mode,
    Value<String?>? businessName,
    Value<String?>? businessId,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      mode: mode ?? this.mode,
      businessName: businessName ?? this.businessName,
      businessId: businessId ?? this.businessId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('mode: $mode, ')
          ..write('businessName: $businessName, ')
          ..write('businessId: $businessId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTable extends Receipts
    with TableInfo<$ReceiptsTable, ReceiptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptNoMeta = const VerificationMeta(
    'receiptNo',
  );
  @override
  late final GeneratedColumn<String> receiptNo = GeneratedColumn<String>(
    'receipt_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellerBusinessIdMeta = const VerificationMeta(
    'sellerBusinessId',
  );
  @override
  late final GeneratedColumn<String> sellerBusinessId = GeneratedColumn<String>(
    'seller_business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellerNameMeta = const VerificationMeta(
    'sellerName',
  );
  @override
  late final GeneratedColumn<String> sellerName = GeneratedColumn<String>(
    'seller_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyerNameMeta = const VerificationMeta(
    'buyerName',
  );
  @override
  late final GeneratedColumn<String> buyerName = GeneratedColumn<String>(
    'buyer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPesewasMeta = const VerificationMeta(
    'totalPesewas',
  );
  @override
  late final GeneratedColumn<int> totalPesewas = GeneratedColumn<int>(
    'total_pesewas',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('GHS'),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuedAtUnixMeta = const VerificationMeta(
    'issuedAtUnix',
  );
  @override
  late final GeneratedColumn<int> issuedAtUnix = GeneratedColumn<int>(
    'issued_at_unix',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qrTextMeta = const VerificationMeta('qrText');
  @override
  late final GeneratedColumn<String> qrText = GeneratedColumn<String>(
    'qr_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalReceiptNoMeta = const VerificationMeta(
    'originalReceiptNo',
  );
  @override
  late final GeneratedColumn<String> originalReceiptNo =
      GeneratedColumn<String>(
        'original_receipt_no',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _verifiedMeta = const VerificationMeta(
    'verified',
  );
  @override
  late final GeneratedColumn<bool> verified = GeneratedColumn<bool>(
    'verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptNo,
    sellerBusinessId,
    sellerName,
    buyerName,
    totalPesewas,
    currency,
    paymentMethod,
    issuedAtUnix,
    source,
    qrText,
    direction,
    originalReceiptNo,
    verified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('receipt_no')) {
      context.handle(
        _receiptNoMeta,
        receiptNo.isAcceptableOrUnknown(data['receipt_no']!, _receiptNoMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptNoMeta);
    }
    if (data.containsKey('seller_business_id')) {
      context.handle(
        _sellerBusinessIdMeta,
        sellerBusinessId.isAcceptableOrUnknown(
          data['seller_business_id']!,
          _sellerBusinessIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sellerBusinessIdMeta);
    }
    if (data.containsKey('seller_name')) {
      context.handle(
        _sellerNameMeta,
        sellerName.isAcceptableOrUnknown(data['seller_name']!, _sellerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sellerNameMeta);
    }
    if (data.containsKey('buyer_name')) {
      context.handle(
        _buyerNameMeta,
        buyerName.isAcceptableOrUnknown(data['buyer_name']!, _buyerNameMeta),
      );
    }
    if (data.containsKey('total_pesewas')) {
      context.handle(
        _totalPesewasMeta,
        totalPesewas.isAcceptableOrUnknown(
          data['total_pesewas']!,
          _totalPesewasMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPesewasMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('issued_at_unix')) {
      context.handle(
        _issuedAtUnixMeta,
        issuedAtUnix.isAcceptableOrUnknown(
          data['issued_at_unix']!,
          _issuedAtUnixMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_issuedAtUnixMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('qr_text')) {
      context.handle(
        _qrTextMeta,
        qrText.isAcceptableOrUnknown(data['qr_text']!, _qrTextMeta),
      );
    } else if (isInserting) {
      context.missing(_qrTextMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('original_receipt_no')) {
      context.handle(
        _originalReceiptNoMeta,
        originalReceiptNo.isAcceptableOrUnknown(
          data['original_receipt_no']!,
          _originalReceiptNoMeta,
        ),
      );
    }
    if (data.containsKey('verified')) {
      context.handle(
        _verifiedMeta,
        verified.isAcceptableOrUnknown(data['verified']!, _verifiedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceiptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      receiptNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_no'],
      )!,
      sellerBusinessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seller_business_id'],
      )!,
      sellerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seller_name'],
      )!,
      buyerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}buyer_name'],
      ),
      totalPesewas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pesewas'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      issuedAtUnix: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}issued_at_unix'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      qrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qr_text'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      originalReceiptNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_receipt_no'],
      ),
      verified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}verified'],
      )!,
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class ReceiptRow extends DataClass implements Insertable<ReceiptRow> {
  final String id;
  final String receiptNo;
  final String sellerBusinessId;
  final String sellerName;
  final String? buyerName;
  final int totalPesewas;
  final String currency;
  final String paymentMethod;
  final int issuedAtUnix;
  final String source;
  final String qrText;
  final String direction;
  final String? originalReceiptNo;
  final bool verified;
  const ReceiptRow({
    required this.id,
    required this.receiptNo,
    required this.sellerBusinessId,
    required this.sellerName,
    this.buyerName,
    required this.totalPesewas,
    required this.currency,
    required this.paymentMethod,
    required this.issuedAtUnix,
    required this.source,
    required this.qrText,
    required this.direction,
    this.originalReceiptNo,
    required this.verified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['receipt_no'] = Variable<String>(receiptNo);
    map['seller_business_id'] = Variable<String>(sellerBusinessId);
    map['seller_name'] = Variable<String>(sellerName);
    if (!nullToAbsent || buyerName != null) {
      map['buyer_name'] = Variable<String>(buyerName);
    }
    map['total_pesewas'] = Variable<int>(totalPesewas);
    map['currency'] = Variable<String>(currency);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['issued_at_unix'] = Variable<int>(issuedAtUnix);
    map['source'] = Variable<String>(source);
    map['qr_text'] = Variable<String>(qrText);
    map['direction'] = Variable<String>(direction);
    if (!nullToAbsent || originalReceiptNo != null) {
      map['original_receipt_no'] = Variable<String>(originalReceiptNo);
    }
    map['verified'] = Variable<bool>(verified);
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      receiptNo: Value(receiptNo),
      sellerBusinessId: Value(sellerBusinessId),
      sellerName: Value(sellerName),
      buyerName: buyerName == null && nullToAbsent
          ? const Value.absent()
          : Value(buyerName),
      totalPesewas: Value(totalPesewas),
      currency: Value(currency),
      paymentMethod: Value(paymentMethod),
      issuedAtUnix: Value(issuedAtUnix),
      source: Value(source),
      qrText: Value(qrText),
      direction: Value(direction),
      originalReceiptNo: originalReceiptNo == null && nullToAbsent
          ? const Value.absent()
          : Value(originalReceiptNo),
      verified: Value(verified),
    );
  }

  factory ReceiptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptRow(
      id: serializer.fromJson<String>(json['id']),
      receiptNo: serializer.fromJson<String>(json['receiptNo']),
      sellerBusinessId: serializer.fromJson<String>(json['sellerBusinessId']),
      sellerName: serializer.fromJson<String>(json['sellerName']),
      buyerName: serializer.fromJson<String?>(json['buyerName']),
      totalPesewas: serializer.fromJson<int>(json['totalPesewas']),
      currency: serializer.fromJson<String>(json['currency']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      issuedAtUnix: serializer.fromJson<int>(json['issuedAtUnix']),
      source: serializer.fromJson<String>(json['source']),
      qrText: serializer.fromJson<String>(json['qrText']),
      direction: serializer.fromJson<String>(json['direction']),
      originalReceiptNo: serializer.fromJson<String?>(
        json['originalReceiptNo'],
      ),
      verified: serializer.fromJson<bool>(json['verified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'receiptNo': serializer.toJson<String>(receiptNo),
      'sellerBusinessId': serializer.toJson<String>(sellerBusinessId),
      'sellerName': serializer.toJson<String>(sellerName),
      'buyerName': serializer.toJson<String?>(buyerName),
      'totalPesewas': serializer.toJson<int>(totalPesewas),
      'currency': serializer.toJson<String>(currency),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'issuedAtUnix': serializer.toJson<int>(issuedAtUnix),
      'source': serializer.toJson<String>(source),
      'qrText': serializer.toJson<String>(qrText),
      'direction': serializer.toJson<String>(direction),
      'originalReceiptNo': serializer.toJson<String?>(originalReceiptNo),
      'verified': serializer.toJson<bool>(verified),
    };
  }

  ReceiptRow copyWith({
    String? id,
    String? receiptNo,
    String? sellerBusinessId,
    String? sellerName,
    Value<String?> buyerName = const Value.absent(),
    int? totalPesewas,
    String? currency,
    String? paymentMethod,
    int? issuedAtUnix,
    String? source,
    String? qrText,
    String? direction,
    Value<String?> originalReceiptNo = const Value.absent(),
    bool? verified,
  }) => ReceiptRow(
    id: id ?? this.id,
    receiptNo: receiptNo ?? this.receiptNo,
    sellerBusinessId: sellerBusinessId ?? this.sellerBusinessId,
    sellerName: sellerName ?? this.sellerName,
    buyerName: buyerName.present ? buyerName.value : this.buyerName,
    totalPesewas: totalPesewas ?? this.totalPesewas,
    currency: currency ?? this.currency,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    issuedAtUnix: issuedAtUnix ?? this.issuedAtUnix,
    source: source ?? this.source,
    qrText: qrText ?? this.qrText,
    direction: direction ?? this.direction,
    originalReceiptNo: originalReceiptNo.present
        ? originalReceiptNo.value
        : this.originalReceiptNo,
    verified: verified ?? this.verified,
  );
  ReceiptRow copyWithCompanion(ReceiptsCompanion data) {
    return ReceiptRow(
      id: data.id.present ? data.id.value : this.id,
      receiptNo: data.receiptNo.present ? data.receiptNo.value : this.receiptNo,
      sellerBusinessId: data.sellerBusinessId.present
          ? data.sellerBusinessId.value
          : this.sellerBusinessId,
      sellerName: data.sellerName.present
          ? data.sellerName.value
          : this.sellerName,
      buyerName: data.buyerName.present ? data.buyerName.value : this.buyerName,
      totalPesewas: data.totalPesewas.present
          ? data.totalPesewas.value
          : this.totalPesewas,
      currency: data.currency.present ? data.currency.value : this.currency,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      issuedAtUnix: data.issuedAtUnix.present
          ? data.issuedAtUnix.value
          : this.issuedAtUnix,
      source: data.source.present ? data.source.value : this.source,
      qrText: data.qrText.present ? data.qrText.value : this.qrText,
      direction: data.direction.present ? data.direction.value : this.direction,
      originalReceiptNo: data.originalReceiptNo.present
          ? data.originalReceiptNo.value
          : this.originalReceiptNo,
      verified: data.verified.present ? data.verified.value : this.verified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptRow(')
          ..write('id: $id, ')
          ..write('receiptNo: $receiptNo, ')
          ..write('sellerBusinessId: $sellerBusinessId, ')
          ..write('sellerName: $sellerName, ')
          ..write('buyerName: $buyerName, ')
          ..write('totalPesewas: $totalPesewas, ')
          ..write('currency: $currency, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('issuedAtUnix: $issuedAtUnix, ')
          ..write('source: $source, ')
          ..write('qrText: $qrText, ')
          ..write('direction: $direction, ')
          ..write('originalReceiptNo: $originalReceiptNo, ')
          ..write('verified: $verified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    receiptNo,
    sellerBusinessId,
    sellerName,
    buyerName,
    totalPesewas,
    currency,
    paymentMethod,
    issuedAtUnix,
    source,
    qrText,
    direction,
    originalReceiptNo,
    verified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptRow &&
          other.id == this.id &&
          other.receiptNo == this.receiptNo &&
          other.sellerBusinessId == this.sellerBusinessId &&
          other.sellerName == this.sellerName &&
          other.buyerName == this.buyerName &&
          other.totalPesewas == this.totalPesewas &&
          other.currency == this.currency &&
          other.paymentMethod == this.paymentMethod &&
          other.issuedAtUnix == this.issuedAtUnix &&
          other.source == this.source &&
          other.qrText == this.qrText &&
          other.direction == this.direction &&
          other.originalReceiptNo == this.originalReceiptNo &&
          other.verified == this.verified);
}

class ReceiptsCompanion extends UpdateCompanion<ReceiptRow> {
  final Value<String> id;
  final Value<String> receiptNo;
  final Value<String> sellerBusinessId;
  final Value<String> sellerName;
  final Value<String?> buyerName;
  final Value<int> totalPesewas;
  final Value<String> currency;
  final Value<String> paymentMethod;
  final Value<int> issuedAtUnix;
  final Value<String> source;
  final Value<String> qrText;
  final Value<String> direction;
  final Value<String?> originalReceiptNo;
  final Value<bool> verified;
  final Value<int> rowid;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.receiptNo = const Value.absent(),
    this.sellerBusinessId = const Value.absent(),
    this.sellerName = const Value.absent(),
    this.buyerName = const Value.absent(),
    this.totalPesewas = const Value.absent(),
    this.currency = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.issuedAtUnix = const Value.absent(),
    this.source = const Value.absent(),
    this.qrText = const Value.absent(),
    this.direction = const Value.absent(),
    this.originalReceiptNo = const Value.absent(),
    this.verified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    required String id,
    required String receiptNo,
    required String sellerBusinessId,
    required String sellerName,
    this.buyerName = const Value.absent(),
    required int totalPesewas,
    this.currency = const Value.absent(),
    required String paymentMethod,
    required int issuedAtUnix,
    required String source,
    required String qrText,
    required String direction,
    this.originalReceiptNo = const Value.absent(),
    this.verified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       receiptNo = Value(receiptNo),
       sellerBusinessId = Value(sellerBusinessId),
       sellerName = Value(sellerName),
       totalPesewas = Value(totalPesewas),
       paymentMethod = Value(paymentMethod),
       issuedAtUnix = Value(issuedAtUnix),
       source = Value(source),
       qrText = Value(qrText),
       direction = Value(direction);
  static Insertable<ReceiptRow> custom({
    Expression<String>? id,
    Expression<String>? receiptNo,
    Expression<String>? sellerBusinessId,
    Expression<String>? sellerName,
    Expression<String>? buyerName,
    Expression<int>? totalPesewas,
    Expression<String>? currency,
    Expression<String>? paymentMethod,
    Expression<int>? issuedAtUnix,
    Expression<String>? source,
    Expression<String>? qrText,
    Expression<String>? direction,
    Expression<String>? originalReceiptNo,
    Expression<bool>? verified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptNo != null) 'receipt_no': receiptNo,
      if (sellerBusinessId != null) 'seller_business_id': sellerBusinessId,
      if (sellerName != null) 'seller_name': sellerName,
      if (buyerName != null) 'buyer_name': buyerName,
      if (totalPesewas != null) 'total_pesewas': totalPesewas,
      if (currency != null) 'currency': currency,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (issuedAtUnix != null) 'issued_at_unix': issuedAtUnix,
      if (source != null) 'source': source,
      if (qrText != null) 'qr_text': qrText,
      if (direction != null) 'direction': direction,
      if (originalReceiptNo != null) 'original_receipt_no': originalReceiptNo,
      if (verified != null) 'verified': verified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptsCompanion copyWith({
    Value<String>? id,
    Value<String>? receiptNo,
    Value<String>? sellerBusinessId,
    Value<String>? sellerName,
    Value<String?>? buyerName,
    Value<int>? totalPesewas,
    Value<String>? currency,
    Value<String>? paymentMethod,
    Value<int>? issuedAtUnix,
    Value<String>? source,
    Value<String>? qrText,
    Value<String>? direction,
    Value<String?>? originalReceiptNo,
    Value<bool>? verified,
    Value<int>? rowid,
  }) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      receiptNo: receiptNo ?? this.receiptNo,
      sellerBusinessId: sellerBusinessId ?? this.sellerBusinessId,
      sellerName: sellerName ?? this.sellerName,
      buyerName: buyerName ?? this.buyerName,
      totalPesewas: totalPesewas ?? this.totalPesewas,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      issuedAtUnix: issuedAtUnix ?? this.issuedAtUnix,
      source: source ?? this.source,
      qrText: qrText ?? this.qrText,
      direction: direction ?? this.direction,
      originalReceiptNo: originalReceiptNo ?? this.originalReceiptNo,
      verified: verified ?? this.verified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (receiptNo.present) {
      map['receipt_no'] = Variable<String>(receiptNo.value);
    }
    if (sellerBusinessId.present) {
      map['seller_business_id'] = Variable<String>(sellerBusinessId.value);
    }
    if (sellerName.present) {
      map['seller_name'] = Variable<String>(sellerName.value);
    }
    if (buyerName.present) {
      map['buyer_name'] = Variable<String>(buyerName.value);
    }
    if (totalPesewas.present) {
      map['total_pesewas'] = Variable<int>(totalPesewas.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (issuedAtUnix.present) {
      map['issued_at_unix'] = Variable<int>(issuedAtUnix.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (qrText.present) {
      map['qr_text'] = Variable<String>(qrText.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (originalReceiptNo.present) {
      map['original_receipt_no'] = Variable<String>(originalReceiptNo.value);
    }
    if (verified.present) {
      map['verified'] = Variable<bool>(verified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('receiptNo: $receiptNo, ')
          ..write('sellerBusinessId: $sellerBusinessId, ')
          ..write('sellerName: $sellerName, ')
          ..write('buyerName: $buyerName, ')
          ..write('totalPesewas: $totalPesewas, ')
          ..write('currency: $currency, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('issuedAtUnix: $issuedAtUnix, ')
          ..write('source: $source, ')
          ..write('qrText: $qrText, ')
          ..write('direction: $direction, ')
          ..write('originalReceiptNo: $originalReceiptNo, ')
          ..write('verified: $verified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptItemsTable extends ReceiptItems
    with TableInfo<$ReceiptItemsTable, ReceiptItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES receipts (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPricePesewasMeta = const VerificationMeta(
    'unitPricePesewas',
  );
  @override
  late final GeneratedColumn<int> unitPricePesewas = GeneratedColumn<int>(
    'unit_price_pesewas',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    name,
    qty,
    unitPricePesewas,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('unit_price_pesewas')) {
      context.handle(
        _unitPricePesewasMeta,
        unitPricePesewas.isAcceptableOrUnknown(
          data['unit_price_pesewas']!,
          _unitPricePesewasMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPricePesewasMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceiptItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      unitPricePesewas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_pesewas'],
      )!,
    );
  }

  @override
  $ReceiptItemsTable createAlias(String alias) {
    return $ReceiptItemsTable(attachedDatabase, alias);
  }
}

class ReceiptItemRow extends DataClass implements Insertable<ReceiptItemRow> {
  final int id;
  final String receiptId;
  final String name;
  final int qty;
  final int unitPricePesewas;
  const ReceiptItemRow({
    required this.id,
    required this.receiptId,
    required this.name,
    required this.qty,
    required this.unitPricePesewas,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['receipt_id'] = Variable<String>(receiptId);
    map['name'] = Variable<String>(name);
    map['qty'] = Variable<int>(qty);
    map['unit_price_pesewas'] = Variable<int>(unitPricePesewas);
    return map;
  }

  ReceiptItemsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptItemsCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      name: Value(name),
      qty: Value(qty),
      unitPricePesewas: Value(unitPricePesewas),
    );
  }

  factory ReceiptItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptItemRow(
      id: serializer.fromJson<int>(json['id']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      name: serializer.fromJson<String>(json['name']),
      qty: serializer.fromJson<int>(json['qty']),
      unitPricePesewas: serializer.fromJson<int>(json['unitPricePesewas']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'receiptId': serializer.toJson<String>(receiptId),
      'name': serializer.toJson<String>(name),
      'qty': serializer.toJson<int>(qty),
      'unitPricePesewas': serializer.toJson<int>(unitPricePesewas),
    };
  }

  ReceiptItemRow copyWith({
    int? id,
    String? receiptId,
    String? name,
    int? qty,
    int? unitPricePesewas,
  }) => ReceiptItemRow(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    name: name ?? this.name,
    qty: qty ?? this.qty,
    unitPricePesewas: unitPricePesewas ?? this.unitPricePesewas,
  );
  ReceiptItemRow copyWithCompanion(ReceiptItemsCompanion data) {
    return ReceiptItemRow(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      name: data.name.present ? data.name.value : this.name,
      qty: data.qty.present ? data.qty.value : this.qty,
      unitPricePesewas: data.unitPricePesewas.present
          ? data.unitPricePesewas.value
          : this.unitPricePesewas,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptItemRow(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('name: $name, ')
          ..write('qty: $qty, ')
          ..write('unitPricePesewas: $unitPricePesewas')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, receiptId, name, qty, unitPricePesewas);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptItemRow &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.name == this.name &&
          other.qty == this.qty &&
          other.unitPricePesewas == this.unitPricePesewas);
}

class ReceiptItemsCompanion extends UpdateCompanion<ReceiptItemRow> {
  final Value<int> id;
  final Value<String> receiptId;
  final Value<String> name;
  final Value<int> qty;
  final Value<int> unitPricePesewas;
  const ReceiptItemsCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.name = const Value.absent(),
    this.qty = const Value.absent(),
    this.unitPricePesewas = const Value.absent(),
  });
  ReceiptItemsCompanion.insert({
    this.id = const Value.absent(),
    required String receiptId,
    required String name,
    required int qty,
    required int unitPricePesewas,
  }) : receiptId = Value(receiptId),
       name = Value(name),
       qty = Value(qty),
       unitPricePesewas = Value(unitPricePesewas);
  static Insertable<ReceiptItemRow> custom({
    Expression<int>? id,
    Expression<String>? receiptId,
    Expression<String>? name,
    Expression<int>? qty,
    Expression<int>? unitPricePesewas,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (name != null) 'name': name,
      if (qty != null) 'qty': qty,
      if (unitPricePesewas != null) 'unit_price_pesewas': unitPricePesewas,
    });
  }

  ReceiptItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? receiptId,
    Value<String>? name,
    Value<int>? qty,
    Value<int>? unitPricePesewas,
  }) {
    return ReceiptItemsCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      unitPricePesewas: unitPricePesewas ?? this.unitPricePesewas,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (unitPricePesewas.present) {
      map['unit_price_pesewas'] = Variable<int>(unitPricePesewas.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptItemsCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('name: $name, ')
          ..write('qty: $qty, ')
          ..write('unitPricePesewas: $unitPricePesewas')
          ..write(')'))
        .toString();
  }
}

class $SellerKeysTable extends SellerKeys
    with TableInfo<$SellerKeysTable, SellerKeyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SellerKeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyB64Meta = const VerificationMeta(
    'publicKeyB64',
  );
  @override
  late final GeneratedColumn<String> publicKeyB64 = GeneratedColumn<String>(
    'public_key_b64',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtUnixMeta = const VerificationMeta(
    'addedAtUnix',
  );
  @override
  late final GeneratedColumn<int> addedAtUnix = GeneratedColumn<int>(
    'added_at_unix',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    businessId,
    businessName,
    publicKeyB64,
    addedAtUnix,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seller_keys';
  @override
  VerificationContext validateIntegrity(
    Insertable<SellerKeyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessNameMeta);
    }
    if (data.containsKey('public_key_b64')) {
      context.handle(
        _publicKeyB64Meta,
        publicKeyB64.isAcceptableOrUnknown(
          data['public_key_b64']!,
          _publicKeyB64Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicKeyB64Meta);
    }
    if (data.containsKey('added_at_unix')) {
      context.handle(
        _addedAtUnixMeta,
        addedAtUnix.isAcceptableOrUnknown(
          data['added_at_unix']!,
          _addedAtUnixMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_addedAtUnixMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {businessId};
  @override
  SellerKeyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SellerKeyRow(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      )!,
      publicKeyB64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key_b64'],
      )!,
      addedAtUnix: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at_unix'],
      )!,
    );
  }

  @override
  $SellerKeysTable createAlias(String alias) {
    return $SellerKeysTable(attachedDatabase, alias);
  }
}

class SellerKeyRow extends DataClass implements Insertable<SellerKeyRow> {
  final String businessId;
  final String businessName;
  final String publicKeyB64;
  final int addedAtUnix;
  const SellerKeyRow({
    required this.businessId,
    required this.businessName,
    required this.publicKeyB64,
    required this.addedAtUnix,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['business_id'] = Variable<String>(businessId);
    map['business_name'] = Variable<String>(businessName);
    map['public_key_b64'] = Variable<String>(publicKeyB64);
    map['added_at_unix'] = Variable<int>(addedAtUnix);
    return map;
  }

  SellerKeysCompanion toCompanion(bool nullToAbsent) {
    return SellerKeysCompanion(
      businessId: Value(businessId),
      businessName: Value(businessName),
      publicKeyB64: Value(publicKeyB64),
      addedAtUnix: Value(addedAtUnix),
    );
  }

  factory SellerKeyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SellerKeyRow(
      businessId: serializer.fromJson<String>(json['businessId']),
      businessName: serializer.fromJson<String>(json['businessName']),
      publicKeyB64: serializer.fromJson<String>(json['publicKeyB64']),
      addedAtUnix: serializer.fromJson<int>(json['addedAtUnix']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'businessId': serializer.toJson<String>(businessId),
      'businessName': serializer.toJson<String>(businessName),
      'publicKeyB64': serializer.toJson<String>(publicKeyB64),
      'addedAtUnix': serializer.toJson<int>(addedAtUnix),
    };
  }

  SellerKeyRow copyWith({
    String? businessId,
    String? businessName,
    String? publicKeyB64,
    int? addedAtUnix,
  }) => SellerKeyRow(
    businessId: businessId ?? this.businessId,
    businessName: businessName ?? this.businessName,
    publicKeyB64: publicKeyB64 ?? this.publicKeyB64,
    addedAtUnix: addedAtUnix ?? this.addedAtUnix,
  );
  SellerKeyRow copyWithCompanion(SellerKeysCompanion data) {
    return SellerKeyRow(
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      publicKeyB64: data.publicKeyB64.present
          ? data.publicKeyB64.value
          : this.publicKeyB64,
      addedAtUnix: data.addedAtUnix.present
          ? data.addedAtUnix.value
          : this.addedAtUnix,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SellerKeyRow(')
          ..write('businessId: $businessId, ')
          ..write('businessName: $businessName, ')
          ..write('publicKeyB64: $publicKeyB64, ')
          ..write('addedAtUnix: $addedAtUnix')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(businessId, businessName, publicKeyB64, addedAtUnix);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SellerKeyRow &&
          other.businessId == this.businessId &&
          other.businessName == this.businessName &&
          other.publicKeyB64 == this.publicKeyB64 &&
          other.addedAtUnix == this.addedAtUnix);
}

class SellerKeysCompanion extends UpdateCompanion<SellerKeyRow> {
  final Value<String> businessId;
  final Value<String> businessName;
  final Value<String> publicKeyB64;
  final Value<int> addedAtUnix;
  final Value<int> rowid;
  const SellerKeysCompanion({
    this.businessId = const Value.absent(),
    this.businessName = const Value.absent(),
    this.publicKeyB64 = const Value.absent(),
    this.addedAtUnix = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SellerKeysCompanion.insert({
    required String businessId,
    required String businessName,
    required String publicKeyB64,
    required int addedAtUnix,
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       businessName = Value(businessName),
       publicKeyB64 = Value(publicKeyB64),
       addedAtUnix = Value(addedAtUnix);
  static Insertable<SellerKeyRow> custom({
    Expression<String>? businessId,
    Expression<String>? businessName,
    Expression<String>? publicKeyB64,
    Expression<int>? addedAtUnix,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (businessId != null) 'business_id': businessId,
      if (businessName != null) 'business_name': businessName,
      if (publicKeyB64 != null) 'public_key_b64': publicKeyB64,
      if (addedAtUnix != null) 'added_at_unix': addedAtUnix,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SellerKeysCompanion copyWith({
    Value<String>? businessId,
    Value<String>? businessName,
    Value<String>? publicKeyB64,
    Value<int>? addedAtUnix,
    Value<int>? rowid,
  }) {
    return SellerKeysCompanion(
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      publicKeyB64: publicKeyB64 ?? this.publicKeyB64,
      addedAtUnix: addedAtUnix ?? this.addedAtUnix,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (publicKeyB64.present) {
      map['public_key_b64'] = Variable<String>(publicKeyB64.value);
    }
    if (addedAtUnix.present) {
      map['added_at_unix'] = Variable<int>(addedAtUnix.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SellerKeysCompanion(')
          ..write('businessId: $businessId, ')
          ..write('businessName: $businessName, ')
          ..write('publicKeyB64: $publicKeyB64, ')
          ..write('addedAtUnix: $addedAtUnix, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUnixMeta = const VerificationMeta(
    'createdAtUnix',
  );
  @override
  late final GeneratedColumn<int> createdAtUnix = GeneratedColumn<int>(
    'created_at_unix',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    payload,
    createdAtUnix,
    attempts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at_unix')) {
      context.handle(
        _createdAtUnixMeta,
        createdAtUnix.isAcceptableOrUnknown(
          data['created_at_unix']!,
          _createdAtUnixMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUnixMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAtUnix: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_unix'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int id;
  final String kind;
  final String payload;
  final int createdAtUnix;
  final int attempts;
  const OutboxRow({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAtUnix,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['payload'] = Variable<String>(payload);
    map['created_at_unix'] = Variable<int>(createdAtUnix);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      id: Value(id),
      kind: Value(kind),
      payload: Value(payload),
      createdAtUnix: Value(createdAtUnix),
      attempts: Value(attempts),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAtUnix: serializer.fromJson<int>(json['createdAtUnix']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'createdAtUnix': serializer.toJson<int>(createdAtUnix),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  OutboxRow copyWith({
    int? id,
    String? kind,
    String? payload,
    int? createdAtUnix,
    int? attempts,
  }) => OutboxRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    createdAtUnix: createdAtUnix ?? this.createdAtUnix,
    attempts: attempts ?? this.attempts,
  );
  OutboxRow copyWithCompanion(SyncOutboxCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAtUnix: data.createdAtUnix.present
          ? data.createdAtUnix.value
          : this.createdAtUnix,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('createdAtUnix: $createdAtUnix, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, payload, createdAtUnix, attempts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.createdAtUnix == this.createdAtUnix &&
          other.attempts == this.attempts);
}

class SyncOutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> payload;
  final Value<int> createdAtUnix;
  final Value<int> attempts;
  const SyncOutboxCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAtUnix = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String payload,
    required int createdAtUnix,
    this.attempts = const Value.absent(),
  }) : kind = Value(kind),
       payload = Value(payload),
       createdAtUnix = Value(createdAtUnix);
  static Insertable<OutboxRow> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<int>? createdAtUnix,
    Expression<int>? attempts,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (createdAtUnix != null) 'created_at_unix': createdAtUnix,
      if (attempts != null) 'attempts': attempts,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? payload,
    Value<int>? createdAtUnix,
    Value<int>? attempts,
  }) {
    return SyncOutboxCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      createdAtUnix: createdAtUnix ?? this.createdAtUnix,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAtUnix.present) {
      map['created_at_unix'] = Variable<int>(createdAtUnix.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('createdAtUnix: $createdAtUnix, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $ReceiptItemsTable receiptItems = $ReceiptItemsTable(this);
  late final $SellerKeysTable sellerKeys = $SellerKeysTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    receipts,
    receiptItems,
    sellerKeys,
    syncOutbox,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String id,
  required String name,
  required String phone,
  required String mode,
  Value<String?> businessName,
  Value<String?> businessId,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> phone,
  Value<String> mode,
  Value<String?> businessName,
  Value<String?> businessId,
  Value<int> rowid,
});

class $$ProfilesTableFilterComposer extends Composer<_$AppDb, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDb, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDb, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ProfilesTable,
          ProfileRow,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (ProfileRow, BaseReferences<_$AppDb, $ProfilesTable, ProfileRow>),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDb db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String?> businessName = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                phone: phone,
                mode: mode,
                businessName: businessName,
                businessId: businessId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String phone,
                required String mode,
                Value<String?> businessName = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                mode: mode,
                businessName: businessName,
                businessId: businessId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, ProfileRow>(table),
                  BaseReferences<_$AppDb, $ProfilesTable, ProfileRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ProfilesTable,
      ProfileRow,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (ProfileRow, BaseReferences<_$AppDb, $ProfilesTable, ProfileRow>),
      ProfileRow,
      PrefetchHooks Function()
    >;
typedef $$ReceiptsTableCreateCompanionBuilder = ReceiptsCompanion Function({
  required String id,
  required String receiptNo,
  required String sellerBusinessId,
  required String sellerName,
  Value<String?> buyerName,
  required int totalPesewas,
  Value<String> currency,
  required String paymentMethod,
  required int issuedAtUnix,
  required String source,
  required String qrText,
  required String direction,
  Value<String?> originalReceiptNo,
  Value<bool> verified,
  Value<int> rowid,
});
typedef $$ReceiptsTableUpdateCompanionBuilder = ReceiptsCompanion Function({
  Value<String> id,
  Value<String> receiptNo,
  Value<String> sellerBusinessId,
  Value<String> sellerName,
  Value<String?> buyerName,
  Value<int> totalPesewas,
  Value<String> currency,
  Value<String> paymentMethod,
  Value<int> issuedAtUnix,
  Value<String> source,
  Value<String> qrText,
  Value<String> direction,
  Value<String?> originalReceiptNo,
  Value<bool> verified,
  Value<int> rowid,
});

final class $$ReceiptsTableReferences
    extends BaseReferences<_$AppDb, $ReceiptsTable, ReceiptRow> {
  $$ReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReceiptItemsTable, List<ReceiptItemRow>>
  _receiptItemsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.receiptItems,
    aliasName: 'receipts__id__receipt_items__receipt_id',
  );

  $$ReceiptItemsTableProcessedTableManager get receiptItemsRefs {
    final manager = $$ReceiptItemsTableTableManager(
      $_db,
      $_db.receiptItems,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReceiptsTableFilterComposer extends Composer<_$AppDb, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptNo => $composableBuilder(
    column: $table.receiptNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellerBusinessId => $composableBuilder(
    column: $table.sellerBusinessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellerName => $composableBuilder(
    column: $table.sellerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buyerName => $composableBuilder(
    column: $table.buyerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPesewas => $composableBuilder(
    column: $table.totalPesewas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get issuedAtUnix => $composableBuilder(
    column: $table.issuedAtUnix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qrText => $composableBuilder(
    column: $table.qrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalReceiptNo => $composableBuilder(
    column: $table.originalReceiptNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> receiptItemsRefs(
    Expression<bool> Function($$ReceiptItemsTableFilterComposer f) f,
  ) {
    final $$ReceiptItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptItems,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptItemsTableFilterComposer(
            $db: $db,
            $table: $db.receiptItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$AppDb, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptNo => $composableBuilder(
    column: $table.receiptNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellerBusinessId => $composableBuilder(
    column: $table.sellerBusinessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellerName => $composableBuilder(
    column: $table.sellerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buyerName => $composableBuilder(
    column: $table.buyerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPesewas => $composableBuilder(
    column: $table.totalPesewas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get issuedAtUnix => $composableBuilder(
    column: $table.issuedAtUnix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qrText => $composableBuilder(
    column: $table.qrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalReceiptNo => $composableBuilder(
    column: $table.originalReceiptNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$AppDb, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get receiptNo =>
      $composableBuilder(column: $table.receiptNo, builder: (column) => column);

  GeneratedColumn<String> get sellerBusinessId => $composableBuilder(
    column: $table.sellerBusinessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sellerName => $composableBuilder(
    column: $table.sellerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get buyerName =>
      $composableBuilder(column: $table.buyerName, builder: (column) => column);

  GeneratedColumn<int> get totalPesewas => $composableBuilder(
    column: $table.totalPesewas,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get issuedAtUnix => $composableBuilder(
    column: $table.issuedAtUnix,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get qrText =>
      $composableBuilder(column: $table.qrText, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get originalReceiptNo => $composableBuilder(
    column: $table.originalReceiptNo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get verified =>
      $composableBuilder(column: $table.verified, builder: (column) => column);

  Expression<T> receiptItemsRefs<T extends Object>(
    Expression<T> Function($$ReceiptItemsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptItems,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.receiptItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ReceiptsTable,
          ReceiptRow,
          $$ReceiptsTableFilterComposer,
          $$ReceiptsTableOrderingComposer,
          $$ReceiptsTableAnnotationComposer,
          $$ReceiptsTableCreateCompanionBuilder,
          $$ReceiptsTableUpdateCompanionBuilder,
          (ReceiptRow, $$ReceiptsTableReferences),
          ReceiptRow,
          PrefetchHooks Function({bool receiptItemsRefs})
        > {
  $$ReceiptsTableTableManager(_$AppDb db, $ReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> receiptNo = const Value.absent(),
                Value<String> sellerBusinessId = const Value.absent(),
                Value<String> sellerName = const Value.absent(),
                Value<String?> buyerName = const Value.absent(),
                Value<int> totalPesewas = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<int> issuedAtUnix = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> qrText = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String?> originalReceiptNo = const Value.absent(),
                Value<bool> verified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion(
                id: id,
                receiptNo: receiptNo,
                sellerBusinessId: sellerBusinessId,
                sellerName: sellerName,
                buyerName: buyerName,
                totalPesewas: totalPesewas,
                currency: currency,
                paymentMethod: paymentMethod,
                issuedAtUnix: issuedAtUnix,
                source: source,
                qrText: qrText,
                direction: direction,
                originalReceiptNo: originalReceiptNo,
                verified: verified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String receiptNo,
                required String sellerBusinessId,
                required String sellerName,
                Value<String?> buyerName = const Value.absent(),
                required int totalPesewas,
                Value<String> currency = const Value.absent(),
                required String paymentMethod,
                required int issuedAtUnix,
                required String source,
                required String qrText,
                required String direction,
                Value<String?> originalReceiptNo = const Value.absent(),
                Value<bool> verified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion.insert(
                id: id,
                receiptNo: receiptNo,
                sellerBusinessId: sellerBusinessId,
                sellerName: sellerName,
                buyerName: buyerName,
                totalPesewas: totalPesewas,
                currency: currency,
                paymentMethod: paymentMethod,
                issuedAtUnix: issuedAtUnix,
                source: source,
                qrText: qrText,
                direction: direction,
                originalReceiptNo: originalReceiptNo,
                verified: verified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceiptsTable, ReceiptRow>(table),
                  $$ReceiptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (receiptItemsRefs) db.receiptItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (receiptItemsRefs)
                    await $_getPrefetchedData<
                      ReceiptRow,
                      $ReceiptsTable,
                      ReceiptItemRow
                    >(
                      currentTable: table,
                      referencedTable: $$ReceiptsTableReferences
                          ._receiptItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ReceiptsTableReferences(
                        db,
                        table,
                        p0,
                      ).receiptItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.receiptId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ReceiptsTable,
      ReceiptRow,
      $$ReceiptsTableFilterComposer,
      $$ReceiptsTableOrderingComposer,
      $$ReceiptsTableAnnotationComposer,
      $$ReceiptsTableCreateCompanionBuilder,
      $$ReceiptsTableUpdateCompanionBuilder,
      (ReceiptRow, $$ReceiptsTableReferences),
      ReceiptRow,
      PrefetchHooks Function({bool receiptItemsRefs})
    >;
typedef $$ReceiptItemsTableCreateCompanionBuilder =
    ReceiptItemsCompanion Function({
      Value<int> id,
      required String receiptId,
      required String name,
      required int qty,
      required int unitPricePesewas,
    });
typedef $$ReceiptItemsTableUpdateCompanionBuilder =
    ReceiptItemsCompanion Function({
      Value<int> id,
      Value<String> receiptId,
      Value<String> name,
      Value<int> qty,
      Value<int> unitPricePesewas,
    });

final class $$ReceiptItemsTableReferences
    extends BaseReferences<_$AppDb, $ReceiptItemsTable, ReceiptItemRow> {
  $$ReceiptItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReceiptsTable _receiptIdTable(_$AppDb db) =>
      db.receipts.createAlias('receipt_items__receipt_id__receipts__id');

  $$ReceiptsTableProcessedTableManager get receiptId {
    final $_column = $_itemColumn<String>('receipt_id')!;

    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReceiptItemsTableFilterComposer
    extends Composer<_$AppDb, $ReceiptItemsTable> {
  $$ReceiptItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPricePesewas => $composableBuilder(
    column: $table.unitPricePesewas,
    builder: (column) => ColumnFilters(column),
  );

  $$ReceiptsTableFilterComposer get receiptId {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptItemsTableOrderingComposer
    extends Composer<_$AppDb, $ReceiptItemsTable> {
  $$ReceiptItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPricePesewas => $composableBuilder(
    column: $table.unitPricePesewas,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReceiptsTableOrderingComposer get receiptId {
    final $$ReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptItemsTableAnnotationComposer
    extends Composer<_$AppDb, $ReceiptItemsTable> {
  $$ReceiptItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get unitPricePesewas => $composableBuilder(
    column: $table.unitPricePesewas,
    builder: (column) => column,
  );

  $$ReceiptsTableAnnotationComposer get receiptId {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptItemsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ReceiptItemsTable,
          ReceiptItemRow,
          $$ReceiptItemsTableFilterComposer,
          $$ReceiptItemsTableOrderingComposer,
          $$ReceiptItemsTableAnnotationComposer,
          $$ReceiptItemsTableCreateCompanionBuilder,
          $$ReceiptItemsTableUpdateCompanionBuilder,
          (ReceiptItemRow, $$ReceiptItemsTableReferences),
          ReceiptItemRow,
          PrefetchHooks Function({bool receiptId})
        > {
  $$ReceiptItemsTableTableManager(_$AppDb db, $ReceiptItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<int> unitPricePesewas = const Value.absent(),
              }) => ReceiptItemsCompanion(
                id: id,
                receiptId: receiptId,
                name: name,
                qty: qty,
                unitPricePesewas: unitPricePesewas,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String receiptId,
                required String name,
                required int qty,
                required int unitPricePesewas,
              }) => ReceiptItemsCompanion.insert(
                id: id,
                receiptId: receiptId,
                name: name,
                qty: qty,
                unitPricePesewas: unitPricePesewas,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceiptItemsTable, ReceiptItemRow>(table),
                  $$ReceiptItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (receiptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.receiptId,
                        referencedTable: $$ReceiptItemsTableReferences
                            ._receiptIdTable(db),
                        referencedColumn: $$ReceiptItemsTableReferences
                            ._receiptIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReceiptItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ReceiptItemsTable,
      ReceiptItemRow,
      $$ReceiptItemsTableFilterComposer,
      $$ReceiptItemsTableOrderingComposer,
      $$ReceiptItemsTableAnnotationComposer,
      $$ReceiptItemsTableCreateCompanionBuilder,
      $$ReceiptItemsTableUpdateCompanionBuilder,
      (ReceiptItemRow, $$ReceiptItemsTableReferences),
      ReceiptItemRow,
      PrefetchHooks Function({bool receiptId})
    >;
typedef $$SellerKeysTableCreateCompanionBuilder = SellerKeysCompanion Function({
  required String businessId,
  required String businessName,
  required String publicKeyB64,
  required int addedAtUnix,
  Value<int> rowid,
});
typedef $$SellerKeysTableUpdateCompanionBuilder = SellerKeysCompanion Function({
  Value<String> businessId,
  Value<String> businessName,
  Value<String> publicKeyB64,
  Value<int> addedAtUnix,
  Value<int> rowid,
});

class $$SellerKeysTableFilterComposer
    extends Composer<_$AppDb, $SellerKeysTable> {
  $$SellerKeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKeyB64 => $composableBuilder(
    column: $table.publicKeyB64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAtUnix => $composableBuilder(
    column: $table.addedAtUnix,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SellerKeysTableOrderingComposer
    extends Composer<_$AppDb, $SellerKeysTable> {
  $$SellerKeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKeyB64 => $composableBuilder(
    column: $table.publicKeyB64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAtUnix => $composableBuilder(
    column: $table.addedAtUnix,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SellerKeysTableAnnotationComposer
    extends Composer<_$AppDb, $SellerKeysTable> {
  $$SellerKeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publicKeyB64 => $composableBuilder(
    column: $table.publicKeyB64,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedAtUnix => $composableBuilder(
    column: $table.addedAtUnix,
    builder: (column) => column,
  );
}

class $$SellerKeysTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $SellerKeysTable,
          SellerKeyRow,
          $$SellerKeysTableFilterComposer,
          $$SellerKeysTableOrderingComposer,
          $$SellerKeysTableAnnotationComposer,
          $$SellerKeysTableCreateCompanionBuilder,
          $$SellerKeysTableUpdateCompanionBuilder,
          (
            SellerKeyRow,
            BaseReferences<_$AppDb, $SellerKeysTable, SellerKeyRow>,
          ),
          SellerKeyRow,
          PrefetchHooks Function()
        > {
  $$SellerKeysTableTableManager(_$AppDb db, $SellerKeysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SellerKeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SellerKeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SellerKeysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> businessId = const Value.absent(),
                Value<String> businessName = const Value.absent(),
                Value<String> publicKeyB64 = const Value.absent(),
                Value<int> addedAtUnix = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SellerKeysCompanion(
                businessId: businessId,
                businessName: businessName,
                publicKeyB64: publicKeyB64,
                addedAtUnix: addedAtUnix,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String businessId,
                required String businessName,
                required String publicKeyB64,
                required int addedAtUnix,
                Value<int> rowid = const Value.absent(),
              }) => SellerKeysCompanion.insert(
                businessId: businessId,
                businessName: businessName,
                publicKeyB64: publicKeyB64,
                addedAtUnix: addedAtUnix,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SellerKeysTable, SellerKeyRow>(table),
                  BaseReferences<_$AppDb, $SellerKeysTable, SellerKeyRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SellerKeysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $SellerKeysTable,
      SellerKeyRow,
      $$SellerKeysTableFilterComposer,
      $$SellerKeysTableOrderingComposer,
      $$SellerKeysTableAnnotationComposer,
      $$SellerKeysTableCreateCompanionBuilder,
      $$SellerKeysTableUpdateCompanionBuilder,
      (SellerKeyRow, BaseReferences<_$AppDb, $SellerKeysTable, SellerKeyRow>),
      SellerKeyRow,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder = SyncOutboxCompanion Function({
  Value<int> id,
  required String kind,
  required String payload,
  required int createdAtUnix,
  Value<int> attempts,
});
typedef $$SyncOutboxTableUpdateCompanionBuilder = SyncOutboxCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<String> payload,
  Value<int> createdAtUnix,
  Value<int> attempts,
});

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDb, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUnix => $composableBuilder(
    column: $table.createdAtUnix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDb, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUnix => $composableBuilder(
    column: $table.createdAtUnix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDb, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAtUnix => $composableBuilder(
    column: $table.createdAtUnix,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $SyncOutboxTable,
          OutboxRow,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (OutboxRow, BaseReferences<_$AppDb, $SyncOutboxTable, OutboxRow>),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableManager(_$AppDb db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> createdAtUnix = const Value.absent(),
                Value<int> attempts = const Value.absent(),
              }) => SyncOutboxCompanion(
                id: id,
                kind: kind,
                payload: payload,
                createdAtUnix: createdAtUnix,
                attempts: attempts,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String payload,
                required int createdAtUnix,
                Value<int> attempts = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                id: id,
                kind: kind,
                payload: payload,
                createdAtUnix: createdAtUnix,
                attempts: attempts,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncOutboxTable, OutboxRow>(table),
                  BaseReferences<_$AppDb, $SyncOutboxTable, OutboxRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $SyncOutboxTable,
      OutboxRow,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDb, $SyncOutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$ReceiptItemsTableTableManager get receiptItems =>
      $$ReceiptItemsTableTableManager(_db, _db.receiptItems);
  $$SellerKeysTableTableManager get sellerKeys =>
      $$SellerKeysTableTableManager(_db, _db.sellerKeys);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
}
