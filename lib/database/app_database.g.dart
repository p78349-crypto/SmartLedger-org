// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DbAccountsTable extends DbAccounts
    with TableInfo<$DbAccountsTable, DbAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbAccountsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    syncId,
    updatedAt,
    isDeleted,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $DbAccountsTable createAlias(String alias) {
    return $DbAccountsTable(attachedDatabase, alias);
  }
}

class DbAccount extends DataClass implements Insertable<DbAccount> {
  final int id;
  final String name;
  final DateTime createdAt;
  final String? syncId;
  final DateTime? updatedAt;
  final bool isDeleted;
  final bool isSynced;
  const DbAccount({
    required this.id,
    required this.name,
    required this.createdAt,
    this.syncId,
    this.updatedAt,
    required this.isDeleted,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  DbAccountsCompanion toCompanion(bool nullToAbsent) {
    return DbAccountsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDeleted: Value(isDeleted),
      isSynced: Value(isSynced),
    );
  }

  factory DbAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbAccount(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncId': serializer.toJson<String?>(syncId),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  DbAccount copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    Value<String?> syncId = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isDeleted,
    bool? isSynced,
  }) => DbAccount(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    syncId: syncId.present ? syncId.value : this.syncId,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    isSynced: isSynced ?? this.isSynced,
  );
  DbAccount copyWithCompanion(DbAccountsCompanion data) {
    return DbAccount(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbAccount(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncId: $syncId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, createdAt, syncId, updatedAt, isDeleted, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbAccount &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.syncId == this.syncId &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.isSynced == this.isSynced);
}

class DbAccountsCompanion extends UpdateCompanion<DbAccount> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<String?> syncId;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> isSynced;
  const DbAccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
  });
  DbAccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
    this.syncId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
  }) : name = Value(name);
  static Insertable<DbAccount> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<String>? syncId,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? isSynced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (syncId != null) 'sync_id': syncId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isSynced != null) 'is_synced': isSynced,
    });
  }

  DbAccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<String?>? syncId,
    Value<DateTime?>? updatedAt,
    Value<bool>? isDeleted,
    Value<bool>? isSynced,
  }) {
    return DbAccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      syncId: syncId ?? this.syncId,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbAccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncId: $syncId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }
}

class $DbTransactionsTable extends DbTransactions
    with TableInfo<$DbTransactionsTable, DbTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES db_accounts (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardChargedAmountMeta = const VerificationMeta(
    'cardChargedAmount',
  );
  @override
  late final GeneratedColumn<double> cardChargedAmount =
      GeneratedColumn<double>(
        'card_charged_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _storeMeta = const VerificationMeta('store');
  @override
  late final GeneratedColumn<String> store = GeneratedColumn<String>(
    'store',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mainCategoryMeta = const VerificationMeta(
    'mainCategory',
  );
  @override
  late final GeneratedColumn<String> mainCategory = GeneratedColumn<String>(
    'main_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('미분류'),
  );
  static const VerificationMeta _subCategoryMeta = const VerificationMeta(
    'subCategory',
  );
  @override
  late final GeneratedColumn<String> subCategory = GeneratedColumn<String>(
    'sub_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailCategoryMeta = const VerificationMeta(
    'detailCategory',
  );
  @override
  late final GeneratedColumn<String> detailCategory = GeneratedColumn<String>(
    'detail_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplierMeta = const VerificationMeta(
    'supplier',
  );
  @override
  late final GeneratedColumn<String> supplier = GeneratedColumn<String>(
    'supplier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    defaultValue: const Constant('KRW'),
  );
  static const VerificationMeta _exchangeRateMeta = const VerificationMeta(
    'exchangeRate',
  );
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
    'exchange_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _originalAmountMeta = const VerificationMeta(
    'originalAmount',
  );
  @override
  late final GeneratedColumn<double> originalAmount = GeneratedColumn<double>(
    'original_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vatAmountMeta = const VerificationMeta(
    'vatAmount',
  );
  @override
  late final GeneratedColumn<double> vatAmount = GeneratedColumn<double>(
    'vat_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _savingsAllocationMeta = const VerificationMeta(
    'savingsAllocation',
  );
  @override
  late final GeneratedColumn<String> savingsAllocation =
      GeneratedColumn<String>(
        'savings_allocation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isRefundMeta = const VerificationMeta(
    'isRefund',
  );
  @override
  late final GeneratedColumn<int> isRefund = GeneratedColumn<int>(
    'is_refund',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _originalTransactionIdMeta =
      const VerificationMeta('originalTransactionId');
  @override
  late final GeneratedColumn<String> originalTransactionId =
      GeneratedColumn<String>(
        'original_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _weatherJsonMeta = const VerificationMeta(
    'weatherJson',
  );
  @override
  late final GeneratedColumn<String> weatherJson = GeneratedColumn<String>(
    'weather_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _benefitJsonMeta = const VerificationMeta(
    'benefitJson',
  );
  @override
  late final GeneratedColumn<String> benefitJson = GeneratedColumn<String>(
    'benefit_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _integrityHashMeta = const VerificationMeta(
    'integrityHash',
  );
  @override
  late final GeneratedColumn<String> integrityHash = GeneratedColumn<String>(
    'integrity_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    type,
    description,
    amount,
    cardChargedAmount,
    date,
    quantity,
    unitPrice,
    paymentMethod,
    memo,
    store,
    mainCategory,
    subCategory,
    detailCategory,
    location,
    supplier,
    expiryDate,
    unit,
    currency,
    exchangeRate,
    originalAmount,
    vatAmount,
    savingsAllocation,
    isRefund,
    originalTransactionId,
    weatherJson,
    benefitJson,
    syncId,
    updatedAt,
    isDeleted,
    isSynced,
    integrityHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('card_charged_amount')) {
      context.handle(
        _cardChargedAmountMeta,
        cardChargedAmount.isAcceptableOrUnknown(
          data['card_charged_amount']!,
          _cardChargedAmountMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
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
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('store')) {
      context.handle(
        _storeMeta,
        store.isAcceptableOrUnknown(data['store']!, _storeMeta),
      );
    }
    if (data.containsKey('main_category')) {
      context.handle(
        _mainCategoryMeta,
        mainCategory.isAcceptableOrUnknown(
          data['main_category']!,
          _mainCategoryMeta,
        ),
      );
    }
    if (data.containsKey('sub_category')) {
      context.handle(
        _subCategoryMeta,
        subCategory.isAcceptableOrUnknown(
          data['sub_category']!,
          _subCategoryMeta,
        ),
      );
    }
    if (data.containsKey('detail_category')) {
      context.handle(
        _detailCategoryMeta,
        detailCategory.isAcceptableOrUnknown(
          data['detail_category']!,
          _detailCategoryMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('supplier')) {
      context.handle(
        _supplierMeta,
        supplier.isAcceptableOrUnknown(data['supplier']!, _supplierMeta),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
        _exchangeRateMeta,
        exchangeRate.isAcceptableOrUnknown(
          data['exchange_rate']!,
          _exchangeRateMeta,
        ),
      );
    }
    if (data.containsKey('original_amount')) {
      context.handle(
        _originalAmountMeta,
        originalAmount.isAcceptableOrUnknown(
          data['original_amount']!,
          _originalAmountMeta,
        ),
      );
    }
    if (data.containsKey('vat_amount')) {
      context.handle(
        _vatAmountMeta,
        vatAmount.isAcceptableOrUnknown(data['vat_amount']!, _vatAmountMeta),
      );
    }
    if (data.containsKey('savings_allocation')) {
      context.handle(
        _savingsAllocationMeta,
        savingsAllocation.isAcceptableOrUnknown(
          data['savings_allocation']!,
          _savingsAllocationMeta,
        ),
      );
    }
    if (data.containsKey('is_refund')) {
      context.handle(
        _isRefundMeta,
        isRefund.isAcceptableOrUnknown(data['is_refund']!, _isRefundMeta),
      );
    }
    if (data.containsKey('original_transaction_id')) {
      context.handle(
        _originalTransactionIdMeta,
        originalTransactionId.isAcceptableOrUnknown(
          data['original_transaction_id']!,
          _originalTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('weather_json')) {
      context.handle(
        _weatherJsonMeta,
        weatherJson.isAcceptableOrUnknown(
          data['weather_json']!,
          _weatherJsonMeta,
        ),
      );
    }
    if (data.containsKey('benefit_json')) {
      context.handle(
        _benefitJsonMeta,
        benefitJson.isAcceptableOrUnknown(
          data['benefit_json']!,
          _benefitJsonMeta,
        ),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('integrity_hash')) {
      context.handle(
        _integrityHashMeta,
        integrityHash.isAcceptableOrUnknown(
          data['integrity_hash']!,
          _integrityHashMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      cardChargedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}card_charged_amount'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      )!,
      store: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store'],
      ),
      mainCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}main_category'],
      )!,
      subCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_category'],
      ),
      detailCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_category'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      supplier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      exchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate'],
      )!,
      originalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}original_amount'],
      ),
      vatAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vat_amount'],
      )!,
      savingsAllocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}savings_allocation'],
      ),
      isRefund: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_refund'],
      )!,
      originalTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_transaction_id'],
      ),
      weatherJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weather_json'],
      ),
      benefitJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}benefit_json'],
      ),
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      integrityHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}integrity_hash'],
      ),
    );
  }

  @override
  $DbTransactionsTable createAlias(String alias) {
    return $DbTransactionsTable(attachedDatabase, alias);
  }
}

class DbTransaction extends DataClass implements Insertable<DbTransaction> {
  final String id;
  final int accountId;
  final String type;
  final String description;
  final double amount;
  final double? cardChargedAmount;
  final DateTime date;
  final int quantity;
  final double unitPrice;
  final String paymentMethod;
  final String memo;
  final String? store;
  final String mainCategory;
  final String? subCategory;
  final String? detailCategory;
  final String? location;
  final String? supplier;
  final DateTime? expiryDate;
  final String? unit;
  final String currency;
  final double exchangeRate;
  final double? originalAmount;
  final double vatAmount;

  /// Savings allocation option for savings transactions.
  ///
  /// Stored as a string (enum name) for forward compatibility.
  final String? savingsAllocation;

  /// Refund marker (SQLite has no bool type; use int 0/1).
  final int isRefund;
  final String? originalTransactionId;

  /// Weather snapshot serialized as JSON (nullable).
  final String? weatherJson;

  /// Structured benefits serialized as JSON (nullable).
  ///
  /// Example: {"카드":1200,"배송":3000}
  final String? benefitJson;
  final String? syncId;
  final DateTime? updatedAt;
  final bool isDeleted;
  final bool isSynced;

  /// SHA-256 해시 체인 — 이전 레코드의 해시를 포함하여 변조 감지.
  final String? integrityHash;
  const DbTransaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.description,
    required this.amount,
    this.cardChargedAmount,
    required this.date,
    required this.quantity,
    required this.unitPrice,
    required this.paymentMethod,
    required this.memo,
    this.store,
    required this.mainCategory,
    this.subCategory,
    this.detailCategory,
    this.location,
    this.supplier,
    this.expiryDate,
    this.unit,
    required this.currency,
    required this.exchangeRate,
    this.originalAmount,
    required this.vatAmount,
    this.savingsAllocation,
    required this.isRefund,
    this.originalTransactionId,
    this.weatherJson,
    this.benefitJson,
    this.syncId,
    this.updatedAt,
    required this.isDeleted,
    required this.isSynced,
    this.integrityHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<int>(accountId);
    map['type'] = Variable<String>(type);
    map['description'] = Variable<String>(description);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || cardChargedAmount != null) {
      map['card_charged_amount'] = Variable<double>(cardChargedAmount);
    }
    map['date'] = Variable<DateTime>(date);
    map['quantity'] = Variable<int>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['memo'] = Variable<String>(memo);
    if (!nullToAbsent || store != null) {
      map['store'] = Variable<String>(store);
    }
    map['main_category'] = Variable<String>(mainCategory);
    if (!nullToAbsent || subCategory != null) {
      map['sub_category'] = Variable<String>(subCategory);
    }
    if (!nullToAbsent || detailCategory != null) {
      map['detail_category'] = Variable<String>(detailCategory);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || supplier != null) {
      map['supplier'] = Variable<String>(supplier);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['currency'] = Variable<String>(currency);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    if (!nullToAbsent || originalAmount != null) {
      map['original_amount'] = Variable<double>(originalAmount);
    }
    map['vat_amount'] = Variable<double>(vatAmount);
    if (!nullToAbsent || savingsAllocation != null) {
      map['savings_allocation'] = Variable<String>(savingsAllocation);
    }
    map['is_refund'] = Variable<int>(isRefund);
    if (!nullToAbsent || originalTransactionId != null) {
      map['original_transaction_id'] = Variable<String>(originalTransactionId);
    }
    if (!nullToAbsent || weatherJson != null) {
      map['weather_json'] = Variable<String>(weatherJson);
    }
    if (!nullToAbsent || benefitJson != null) {
      map['benefit_json'] = Variable<String>(benefitJson);
    }
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || integrityHash != null) {
      map['integrity_hash'] = Variable<String>(integrityHash);
    }
    return map;
  }

  DbTransactionsCompanion toCompanion(bool nullToAbsent) {
    return DbTransactionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      type: Value(type),
      description: Value(description),
      amount: Value(amount),
      cardChargedAmount: cardChargedAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(cardChargedAmount),
      date: Value(date),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      paymentMethod: Value(paymentMethod),
      memo: Value(memo),
      store: store == null && nullToAbsent
          ? const Value.absent()
          : Value(store),
      mainCategory: Value(mainCategory),
      subCategory: subCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subCategory),
      detailCategory: detailCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(detailCategory),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      supplier: supplier == null && nullToAbsent
          ? const Value.absent()
          : Value(supplier),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      currency: Value(currency),
      exchangeRate: Value(exchangeRate),
      originalAmount: originalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(originalAmount),
      vatAmount: Value(vatAmount),
      savingsAllocation: savingsAllocation == null && nullToAbsent
          ? const Value.absent()
          : Value(savingsAllocation),
      isRefund: Value(isRefund),
      originalTransactionId: originalTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalTransactionId),
      weatherJson: weatherJson == null && nullToAbsent
          ? const Value.absent()
          : Value(weatherJson),
      benefitJson: benefitJson == null && nullToAbsent
          ? const Value.absent()
          : Value(benefitJson),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDeleted: Value(isDeleted),
      isSynced: Value(isSynced),
      integrityHash: integrityHash == null && nullToAbsent
          ? const Value.absent()
          : Value(integrityHash),
    );
  }

  factory DbTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbTransaction(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<int>(json['accountId']),
      type: serializer.fromJson<String>(json['type']),
      description: serializer.fromJson<String>(json['description']),
      amount: serializer.fromJson<double>(json['amount']),
      cardChargedAmount: serializer.fromJson<double?>(
        json['cardChargedAmount'],
      ),
      date: serializer.fromJson<DateTime>(json['date']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      memo: serializer.fromJson<String>(json['memo']),
      store: serializer.fromJson<String?>(json['store']),
      mainCategory: serializer.fromJson<String>(json['mainCategory']),
      subCategory: serializer.fromJson<String?>(json['subCategory']),
      detailCategory: serializer.fromJson<String?>(json['detailCategory']),
      location: serializer.fromJson<String?>(json['location']),
      supplier: serializer.fromJson<String?>(json['supplier']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      unit: serializer.fromJson<String?>(json['unit']),
      currency: serializer.fromJson<String>(json['currency']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      originalAmount: serializer.fromJson<double?>(json['originalAmount']),
      vatAmount: serializer.fromJson<double>(json['vatAmount']),
      savingsAllocation: serializer.fromJson<String?>(
        json['savingsAllocation'],
      ),
      isRefund: serializer.fromJson<int>(json['isRefund']),
      originalTransactionId: serializer.fromJson<String?>(
        json['originalTransactionId'],
      ),
      weatherJson: serializer.fromJson<String?>(json['weatherJson']),
      benefitJson: serializer.fromJson<String?>(json['benefitJson']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      integrityHash: serializer.fromJson<String?>(json['integrityHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<int>(accountId),
      'type': serializer.toJson<String>(type),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<double>(amount),
      'cardChargedAmount': serializer.toJson<double?>(cardChargedAmount),
      'date': serializer.toJson<DateTime>(date),
      'quantity': serializer.toJson<int>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'memo': serializer.toJson<String>(memo),
      'store': serializer.toJson<String?>(store),
      'mainCategory': serializer.toJson<String>(mainCategory),
      'subCategory': serializer.toJson<String?>(subCategory),
      'detailCategory': serializer.toJson<String?>(detailCategory),
      'location': serializer.toJson<String?>(location),
      'supplier': serializer.toJson<String?>(supplier),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'unit': serializer.toJson<String?>(unit),
      'currency': serializer.toJson<String>(currency),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'originalAmount': serializer.toJson<double?>(originalAmount),
      'vatAmount': serializer.toJson<double>(vatAmount),
      'savingsAllocation': serializer.toJson<String?>(savingsAllocation),
      'isRefund': serializer.toJson<int>(isRefund),
      'originalTransactionId': serializer.toJson<String?>(
        originalTransactionId,
      ),
      'weatherJson': serializer.toJson<String?>(weatherJson),
      'benefitJson': serializer.toJson<String?>(benefitJson),
      'syncId': serializer.toJson<String?>(syncId),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isSynced': serializer.toJson<bool>(isSynced),
      'integrityHash': serializer.toJson<String?>(integrityHash),
    };
  }

  DbTransaction copyWith({
    String? id,
    int? accountId,
    String? type,
    String? description,
    double? amount,
    Value<double?> cardChargedAmount = const Value.absent(),
    DateTime? date,
    int? quantity,
    double? unitPrice,
    String? paymentMethod,
    String? memo,
    Value<String?> store = const Value.absent(),
    String? mainCategory,
    Value<String?> subCategory = const Value.absent(),
    Value<String?> detailCategory = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> supplier = const Value.absent(),
    Value<DateTime?> expiryDate = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    String? currency,
    double? exchangeRate,
    Value<double?> originalAmount = const Value.absent(),
    double? vatAmount,
    Value<String?> savingsAllocation = const Value.absent(),
    int? isRefund,
    Value<String?> originalTransactionId = const Value.absent(),
    Value<String?> weatherJson = const Value.absent(),
    Value<String?> benefitJson = const Value.absent(),
    Value<String?> syncId = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isDeleted,
    bool? isSynced,
    Value<String?> integrityHash = const Value.absent(),
  }) => DbTransaction(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    type: type ?? this.type,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    cardChargedAmount: cardChargedAmount.present
        ? cardChargedAmount.value
        : this.cardChargedAmount,
    date: date ?? this.date,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    memo: memo ?? this.memo,
    store: store.present ? store.value : this.store,
    mainCategory: mainCategory ?? this.mainCategory,
    subCategory: subCategory.present ? subCategory.value : this.subCategory,
    detailCategory: detailCategory.present
        ? detailCategory.value
        : this.detailCategory,
    location: location.present ? location.value : this.location,
    supplier: supplier.present ? supplier.value : this.supplier,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    unit: unit.present ? unit.value : this.unit,
    currency: currency ?? this.currency,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    originalAmount: originalAmount.present
        ? originalAmount.value
        : this.originalAmount,
    vatAmount: vatAmount ?? this.vatAmount,
    savingsAllocation: savingsAllocation.present
        ? savingsAllocation.value
        : this.savingsAllocation,
    isRefund: isRefund ?? this.isRefund,
    originalTransactionId: originalTransactionId.present
        ? originalTransactionId.value
        : this.originalTransactionId,
    weatherJson: weatherJson.present ? weatherJson.value : this.weatherJson,
    benefitJson: benefitJson.present ? benefitJson.value : this.benefitJson,
    syncId: syncId.present ? syncId.value : this.syncId,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    isSynced: isSynced ?? this.isSynced,
    integrityHash: integrityHash.present
        ? integrityHash.value
        : this.integrityHash,
  );
  DbTransaction copyWithCompanion(DbTransactionsCompanion data) {
    return DbTransaction(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      type: data.type.present ? data.type.value : this.type,
      description: data.description.present
          ? data.description.value
          : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      cardChargedAmount: data.cardChargedAmount.present
          ? data.cardChargedAmount.value
          : this.cardChargedAmount,
      date: data.date.present ? data.date.value : this.date,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      memo: data.memo.present ? data.memo.value : this.memo,
      store: data.store.present ? data.store.value : this.store,
      mainCategory: data.mainCategory.present
          ? data.mainCategory.value
          : this.mainCategory,
      subCategory: data.subCategory.present
          ? data.subCategory.value
          : this.subCategory,
      detailCategory: data.detailCategory.present
          ? data.detailCategory.value
          : this.detailCategory,
      location: data.location.present ? data.location.value : this.location,
      supplier: data.supplier.present ? data.supplier.value : this.supplier,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      unit: data.unit.present ? data.unit.value : this.unit,
      currency: data.currency.present ? data.currency.value : this.currency,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      originalAmount: data.originalAmount.present
          ? data.originalAmount.value
          : this.originalAmount,
      vatAmount: data.vatAmount.present ? data.vatAmount.value : this.vatAmount,
      savingsAllocation: data.savingsAllocation.present
          ? data.savingsAllocation.value
          : this.savingsAllocation,
      isRefund: data.isRefund.present ? data.isRefund.value : this.isRefund,
      originalTransactionId: data.originalTransactionId.present
          ? data.originalTransactionId.value
          : this.originalTransactionId,
      weatherJson: data.weatherJson.present
          ? data.weatherJson.value
          : this.weatherJson,
      benefitJson: data.benefitJson.present
          ? data.benefitJson.value
          : this.benefitJson,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      integrityHash: data.integrityHash.present
          ? data.integrityHash.value
          : this.integrityHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbTransaction(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('cardChargedAmount: $cardChargedAmount, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('memo: $memo, ')
          ..write('store: $store, ')
          ..write('mainCategory: $mainCategory, ')
          ..write('subCategory: $subCategory, ')
          ..write('detailCategory: $detailCategory, ')
          ..write('location: $location, ')
          ..write('supplier: $supplier, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('unit: $unit, ')
          ..write('currency: $currency, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('vatAmount: $vatAmount, ')
          ..write('savingsAllocation: $savingsAllocation, ')
          ..write('isRefund: $isRefund, ')
          ..write('originalTransactionId: $originalTransactionId, ')
          ..write('weatherJson: $weatherJson, ')
          ..write('benefitJson: $benefitJson, ')
          ..write('syncId: $syncId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('integrityHash: $integrityHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    accountId,
    type,
    description,
    amount,
    cardChargedAmount,
    date,
    quantity,
    unitPrice,
    paymentMethod,
    memo,
    store,
    mainCategory,
    subCategory,
    detailCategory,
    location,
    supplier,
    expiryDate,
    unit,
    currency,
    exchangeRate,
    originalAmount,
    vatAmount,
    savingsAllocation,
    isRefund,
    originalTransactionId,
    weatherJson,
    benefitJson,
    syncId,
    updatedAt,
    isDeleted,
    isSynced,
    integrityHash,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbTransaction &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.type == this.type &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.cardChargedAmount == this.cardChargedAmount &&
          other.date == this.date &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.paymentMethod == this.paymentMethod &&
          other.memo == this.memo &&
          other.store == this.store &&
          other.mainCategory == this.mainCategory &&
          other.subCategory == this.subCategory &&
          other.detailCategory == this.detailCategory &&
          other.location == this.location &&
          other.supplier == this.supplier &&
          other.expiryDate == this.expiryDate &&
          other.unit == this.unit &&
          other.currency == this.currency &&
          other.exchangeRate == this.exchangeRate &&
          other.originalAmount == this.originalAmount &&
          other.vatAmount == this.vatAmount &&
          other.savingsAllocation == this.savingsAllocation &&
          other.isRefund == this.isRefund &&
          other.originalTransactionId == this.originalTransactionId &&
          other.weatherJson == this.weatherJson &&
          other.benefitJson == this.benefitJson &&
          other.syncId == this.syncId &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.isSynced == this.isSynced &&
          other.integrityHash == this.integrityHash);
}

class DbTransactionsCompanion extends UpdateCompanion<DbTransaction> {
  final Value<String> id;
  final Value<int> accountId;
  final Value<String> type;
  final Value<String> description;
  final Value<double> amount;
  final Value<double?> cardChargedAmount;
  final Value<DateTime> date;
  final Value<int> quantity;
  final Value<double> unitPrice;
  final Value<String> paymentMethod;
  final Value<String> memo;
  final Value<String?> store;
  final Value<String> mainCategory;
  final Value<String?> subCategory;
  final Value<String?> detailCategory;
  final Value<String?> location;
  final Value<String?> supplier;
  final Value<DateTime?> expiryDate;
  final Value<String?> unit;
  final Value<String> currency;
  final Value<double> exchangeRate;
  final Value<double?> originalAmount;
  final Value<double> vatAmount;
  final Value<String?> savingsAllocation;
  final Value<int> isRefund;
  final Value<String?> originalTransactionId;
  final Value<String?> weatherJson;
  final Value<String?> benefitJson;
  final Value<String?> syncId;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> isSynced;
  final Value<String?> integrityHash;
  final Value<int> rowid;
  const DbTransactionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.cardChargedAmount = const Value.absent(),
    this.date = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.memo = const Value.absent(),
    this.store = const Value.absent(),
    this.mainCategory = const Value.absent(),
    this.subCategory = const Value.absent(),
    this.detailCategory = const Value.absent(),
    this.location = const Value.absent(),
    this.supplier = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.unit = const Value.absent(),
    this.currency = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.originalAmount = const Value.absent(),
    this.vatAmount = const Value.absent(),
    this.savingsAllocation = const Value.absent(),
    this.isRefund = const Value.absent(),
    this.originalTransactionId = const Value.absent(),
    this.weatherJson = const Value.absent(),
    this.benefitJson = const Value.absent(),
    this.syncId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.integrityHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbTransactionsCompanion.insert({
    required String id,
    required int accountId,
    required String type,
    this.description = const Value.absent(),
    required double amount,
    this.cardChargedAmount = const Value.absent(),
    required DateTime date,
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.memo = const Value.absent(),
    this.store = const Value.absent(),
    this.mainCategory = const Value.absent(),
    this.subCategory = const Value.absent(),
    this.detailCategory = const Value.absent(),
    this.location = const Value.absent(),
    this.supplier = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.unit = const Value.absent(),
    this.currency = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.originalAmount = const Value.absent(),
    this.vatAmount = const Value.absent(),
    this.savingsAllocation = const Value.absent(),
    this.isRefund = const Value.absent(),
    this.originalTransactionId = const Value.absent(),
    this.weatherJson = const Value.absent(),
    this.benefitJson = const Value.absent(),
    this.syncId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.integrityHash = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       type = Value(type),
       amount = Value(amount),
       date = Value(date);
  static Insertable<DbTransaction> custom({
    Expression<String>? id,
    Expression<int>? accountId,
    Expression<String>? type,
    Expression<String>? description,
    Expression<double>? amount,
    Expression<double>? cardChargedAmount,
    Expression<DateTime>? date,
    Expression<int>? quantity,
    Expression<double>? unitPrice,
    Expression<String>? paymentMethod,
    Expression<String>? memo,
    Expression<String>? store,
    Expression<String>? mainCategory,
    Expression<String>? subCategory,
    Expression<String>? detailCategory,
    Expression<String>? location,
    Expression<String>? supplier,
    Expression<DateTime>? expiryDate,
    Expression<String>? unit,
    Expression<String>? currency,
    Expression<double>? exchangeRate,
    Expression<double>? originalAmount,
    Expression<double>? vatAmount,
    Expression<String>? savingsAllocation,
    Expression<int>? isRefund,
    Expression<String>? originalTransactionId,
    Expression<String>? weatherJson,
    Expression<String>? benefitJson,
    Expression<String>? syncId,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? isSynced,
    Expression<String>? integrityHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (cardChargedAmount != null) 'card_charged_amount': cardChargedAmount,
      if (date != null) 'date': date,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (memo != null) 'memo': memo,
      if (store != null) 'store': store,
      if (mainCategory != null) 'main_category': mainCategory,
      if (subCategory != null) 'sub_category': subCategory,
      if (detailCategory != null) 'detail_category': detailCategory,
      if (location != null) 'location': location,
      if (supplier != null) 'supplier': supplier,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (unit != null) 'unit': unit,
      if (currency != null) 'currency': currency,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (originalAmount != null) 'original_amount': originalAmount,
      if (vatAmount != null) 'vat_amount': vatAmount,
      if (savingsAllocation != null) 'savings_allocation': savingsAllocation,
      if (isRefund != null) 'is_refund': isRefund,
      if (originalTransactionId != null)
        'original_transaction_id': originalTransactionId,
      if (weatherJson != null) 'weather_json': weatherJson,
      if (benefitJson != null) 'benefit_json': benefitJson,
      if (syncId != null) 'sync_id': syncId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (integrityHash != null) 'integrity_hash': integrityHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbTransactionsCompanion copyWith({
    Value<String>? id,
    Value<int>? accountId,
    Value<String>? type,
    Value<String>? description,
    Value<double>? amount,
    Value<double?>? cardChargedAmount,
    Value<DateTime>? date,
    Value<int>? quantity,
    Value<double>? unitPrice,
    Value<String>? paymentMethod,
    Value<String>? memo,
    Value<String?>? store,
    Value<String>? mainCategory,
    Value<String?>? subCategory,
    Value<String?>? detailCategory,
    Value<String?>? location,
    Value<String?>? supplier,
    Value<DateTime?>? expiryDate,
    Value<String?>? unit,
    Value<String>? currency,
    Value<double>? exchangeRate,
    Value<double?>? originalAmount,
    Value<double>? vatAmount,
    Value<String?>? savingsAllocation,
    Value<int>? isRefund,
    Value<String?>? originalTransactionId,
    Value<String?>? weatherJson,
    Value<String?>? benefitJson,
    Value<String?>? syncId,
    Value<DateTime?>? updatedAt,
    Value<bool>? isDeleted,
    Value<bool>? isSynced,
    Value<String?>? integrityHash,
    Value<int>? rowid,
  }) {
    return DbTransactionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      cardChargedAmount: cardChargedAmount ?? this.cardChargedAmount,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      memo: memo ?? this.memo,
      store: store ?? this.store,
      mainCategory: mainCategory ?? this.mainCategory,
      subCategory: subCategory ?? this.subCategory,
      detailCategory: detailCategory ?? this.detailCategory,
      location: location ?? this.location,
      supplier: supplier ?? this.supplier,
      expiryDate: expiryDate ?? this.expiryDate,
      unit: unit ?? this.unit,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      originalAmount: originalAmount ?? this.originalAmount,
      vatAmount: vatAmount ?? this.vatAmount,
      savingsAllocation: savingsAllocation ?? this.savingsAllocation,
      isRefund: isRefund ?? this.isRefund,
      originalTransactionId:
          originalTransactionId ?? this.originalTransactionId,
      weatherJson: weatherJson ?? this.weatherJson,
      benefitJson: benefitJson ?? this.benefitJson,
      syncId: syncId ?? this.syncId,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
      integrityHash: integrityHash ?? this.integrityHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (cardChargedAmount.present) {
      map['card_charged_amount'] = Variable<double>(cardChargedAmount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (store.present) {
      map['store'] = Variable<String>(store.value);
    }
    if (mainCategory.present) {
      map['main_category'] = Variable<String>(mainCategory.value);
    }
    if (subCategory.present) {
      map['sub_category'] = Variable<String>(subCategory.value);
    }
    if (detailCategory.present) {
      map['detail_category'] = Variable<String>(detailCategory.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (supplier.present) {
      map['supplier'] = Variable<String>(supplier.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (originalAmount.present) {
      map['original_amount'] = Variable<double>(originalAmount.value);
    }
    if (vatAmount.present) {
      map['vat_amount'] = Variable<double>(vatAmount.value);
    }
    if (savingsAllocation.present) {
      map['savings_allocation'] = Variable<String>(savingsAllocation.value);
    }
    if (isRefund.present) {
      map['is_refund'] = Variable<int>(isRefund.value);
    }
    if (originalTransactionId.present) {
      map['original_transaction_id'] = Variable<String>(
        originalTransactionId.value,
      );
    }
    if (weatherJson.present) {
      map['weather_json'] = Variable<String>(weatherJson.value);
    }
    if (benefitJson.present) {
      map['benefit_json'] = Variable<String>(benefitJson.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (integrityHash.present) {
      map['integrity_hash'] = Variable<String>(integrityHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('cardChargedAmount: $cardChargedAmount, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('memo: $memo, ')
          ..write('store: $store, ')
          ..write('mainCategory: $mainCategory, ')
          ..write('subCategory: $subCategory, ')
          ..write('detailCategory: $detailCategory, ')
          ..write('location: $location, ')
          ..write('supplier: $supplier, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('unit: $unit, ')
          ..write('currency: $currency, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('vatAmount: $vatAmount, ')
          ..write('savingsAllocation: $savingsAllocation, ')
          ..write('isRefund: $isRefund, ')
          ..write('originalTransactionId: $originalTransactionId, ')
          ..write('weatherJson: $weatherJson, ')
          ..write('benefitJson: $benefitJson, ')
          ..write('syncId: $syncId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('integrityHash: $integrityHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbAssetsTable extends DbAssets with TableInfo<$DbAssetsTable, DbAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbAssetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES db_accounts (id)',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    category,
    name,
    amount,
    location,
    memo,
    updatedAt,
    syncId,
    isDeleted,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbAsset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbAsset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $DbAssetsTable createAlias(String alias) {
    return $DbAssetsTable(attachedDatabase, alias);
  }
}

class DbAsset extends DataClass implements Insertable<DbAsset> {
  final int id;
  final int accountId;
  final String? category;
  final String name;
  final double amount;
  final String? location;
  final String? memo;
  final DateTime? updatedAt;
  final String? syncId;
  final bool isDeleted;
  final bool isSynced;
  const DbAsset({
    required this.id,
    required this.accountId,
    this.category,
    required this.name,
    required this.amount,
    this.location,
    this.memo,
    this.updatedAt,
    this.syncId,
    required this.isDeleted,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<int>(accountId);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  DbAssetsCompanion toCompanion(bool nullToAbsent) {
    return DbAssetsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      name: Value(name),
      amount: Value(amount),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      isDeleted: Value(isDeleted),
      isSynced: Value(isSynced),
    );
  }

  factory DbAsset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbAsset(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<int>(json['accountId']),
      category: serializer.fromJson<String?>(json['category']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      location: serializer.fromJson<String?>(json['location']),
      memo: serializer.fromJson<String?>(json['memo']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<int>(accountId),
      'category': serializer.toJson<String?>(category),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'location': serializer.toJson<String?>(location),
      'memo': serializer.toJson<String?>(memo),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'syncId': serializer.toJson<String?>(syncId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  DbAsset copyWith({
    int? id,
    int? accountId,
    Value<String?> category = const Value.absent(),
    String? name,
    double? amount,
    Value<String?> location = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<String?> syncId = const Value.absent(),
    bool? isDeleted,
    bool? isSynced,
  }) => DbAsset(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    category: category.present ? category.value : this.category,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    location: location.present ? location.value : this.location,
    memo: memo.present ? memo.value : this.memo,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    syncId: syncId.present ? syncId.value : this.syncId,
    isDeleted: isDeleted ?? this.isDeleted,
    isSynced: isSynced ?? this.isSynced,
  );
  DbAsset copyWithCompanion(DbAssetsCompanion data) {
    return DbAsset(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      category: data.category.present ? data.category.value : this.category,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      location: data.location.present ? data.location.value : this.location,
      memo: data.memo.present ? data.memo.value : this.memo,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbAsset(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('category: $category, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('location: $location, ')
          ..write('memo: $memo, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncId: $syncId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    category,
    name,
    amount,
    location,
    memo,
    updatedAt,
    syncId,
    isDeleted,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbAsset &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.category == this.category &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.location == this.location &&
          other.memo == this.memo &&
          other.updatedAt == this.updatedAt &&
          other.syncId == this.syncId &&
          other.isDeleted == this.isDeleted &&
          other.isSynced == this.isSynced);
}

class DbAssetsCompanion extends UpdateCompanion<DbAsset> {
  final Value<int> id;
  final Value<int> accountId;
  final Value<String?> category;
  final Value<String> name;
  final Value<double> amount;
  final Value<String?> location;
  final Value<String?> memo;
  final Value<DateTime?> updatedAt;
  final Value<String?> syncId;
  final Value<bool> isDeleted;
  final Value<bool> isSynced;
  const DbAssetsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.category = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.location = const Value.absent(),
    this.memo = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
  });
  DbAssetsCompanion.insert({
    this.id = const Value.absent(),
    required int accountId,
    this.category = const Value.absent(),
    required String name,
    required double amount,
    this.location = const Value.absent(),
    this.memo = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
  }) : accountId = Value(accountId),
       name = Value(name),
       amount = Value(amount);
  static Insertable<DbAsset> custom({
    Expression<int>? id,
    Expression<int>? accountId,
    Expression<String>? category,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? location,
    Expression<String>? memo,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncId,
    Expression<bool>? isDeleted,
    Expression<bool>? isSynced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (category != null) 'category': category,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (location != null) 'location': location,
      if (memo != null) 'memo': memo,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncId != null) 'sync_id': syncId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isSynced != null) 'is_synced': isSynced,
    });
  }

  DbAssetsCompanion copyWith({
    Value<int>? id,
    Value<int>? accountId,
    Value<String?>? category,
    Value<String>? name,
    Value<double>? amount,
    Value<String?>? location,
    Value<String?>? memo,
    Value<DateTime?>? updatedAt,
    Value<String?>? syncId,
    Value<bool>? isDeleted,
    Value<bool>? isSynced,
  }) {
    return DbAssetsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      category: category ?? this.category,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      updatedAt: updatedAt ?? this.updatedAt,
      syncId: syncId ?? this.syncId,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbAssetsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('category: $category, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('location: $location, ')
          ..write('memo: $memo, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncId: $syncId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }
}

class $DbFixedCostsTable extends DbFixedCosts
    with TableInfo<$DbFixedCostsTable, DbFixedCost> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbFixedCostsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES db_accounts (id)',
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleMeta = const VerificationMeta('cycle');
  @override
  late final GeneratedColumn<String> cycle = GeneratedColumn<String>(
    'cycle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextDueDateMeta = const VerificationMeta(
    'nextDueDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextDueDate = GeneratedColumn<DateTime>(
    'next_due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    name,
    amount,
    cycle,
    nextDueDate,
    memo,
    syncId,
    updatedAt,
    isDeleted,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_fixed_costs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbFixedCost> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('cycle')) {
      context.handle(
        _cycleMeta,
        cycle.isAcceptableOrUnknown(data['cycle']!, _cycleMeta),
      );
    }
    if (data.containsKey('next_due_date')) {
      context.handle(
        _nextDueDateMeta,
        nextDueDate.isAcceptableOrUnknown(
          data['next_due_date']!,
          _nextDueDateMeta,
        ),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbFixedCost map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbFixedCost(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      cycle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle'],
      ),
      nextDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_due_date'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $DbFixedCostsTable createAlias(String alias) {
    return $DbFixedCostsTable(attachedDatabase, alias);
  }
}

class DbFixedCost extends DataClass implements Insertable<DbFixedCost> {
  final int id;
  final int accountId;
  final String name;
  final double amount;
  final String? cycle;
  final DateTime? nextDueDate;
  final String? memo;
  final String? syncId;
  final DateTime? updatedAt;
  final bool isDeleted;
  final bool isSynced;
  const DbFixedCost({
    required this.id,
    required this.accountId,
    required this.name,
    required this.amount,
    this.cycle,
    this.nextDueDate,
    this.memo,
    this.syncId,
    this.updatedAt,
    required this.isDeleted,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<int>(accountId);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || cycle != null) {
      map['cycle'] = Variable<String>(cycle);
    }
    if (!nullToAbsent || nextDueDate != null) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  DbFixedCostsCompanion toCompanion(bool nullToAbsent) {
    return DbFixedCostsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      name: Value(name),
      amount: Value(amount),
      cycle: cycle == null && nullToAbsent
          ? const Value.absent()
          : Value(cycle),
      nextDueDate: nextDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDueDate),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDeleted: Value(isDeleted),
      isSynced: Value(isSynced),
    );
  }

  factory DbFixedCost.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbFixedCost(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<int>(json['accountId']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      cycle: serializer.fromJson<String?>(json['cycle']),
      nextDueDate: serializer.fromJson<DateTime?>(json['nextDueDate']),
      memo: serializer.fromJson<String?>(json['memo']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<int>(accountId),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'cycle': serializer.toJson<String?>(cycle),
      'nextDueDate': serializer.toJson<DateTime?>(nextDueDate),
      'memo': serializer.toJson<String?>(memo),
      'syncId': serializer.toJson<String?>(syncId),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  DbFixedCost copyWith({
    int? id,
    int? accountId,
    String? name,
    double? amount,
    Value<String?> cycle = const Value.absent(),
    Value<DateTime?> nextDueDate = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    Value<String?> syncId = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isDeleted,
    bool? isSynced,
  }) => DbFixedCost(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    cycle: cycle.present ? cycle.value : this.cycle,
    nextDueDate: nextDueDate.present ? nextDueDate.value : this.nextDueDate,
    memo: memo.present ? memo.value : this.memo,
    syncId: syncId.present ? syncId.value : this.syncId,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    isSynced: isSynced ?? this.isSynced,
  );
  DbFixedCost copyWithCompanion(DbFixedCostsCompanion data) {
    return DbFixedCost(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      cycle: data.cycle.present ? data.cycle.value : this.cycle,
      nextDueDate: data.nextDueDate.present
          ? data.nextDueDate.value
          : this.nextDueDate,
      memo: data.memo.present ? data.memo.value : this.memo,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbFixedCost(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('cycle: $cycle, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('memo: $memo, ')
          ..write('syncId: $syncId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    name,
    amount,
    cycle,
    nextDueDate,
    memo,
    syncId,
    updatedAt,
    isDeleted,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbFixedCost &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.cycle == this.cycle &&
          other.nextDueDate == this.nextDueDate &&
          other.memo == this.memo &&
          other.syncId == this.syncId &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.isSynced == this.isSynced);
}

class DbFixedCostsCompanion extends UpdateCompanion<DbFixedCost> {
  final Value<int> id;
  final Value<int> accountId;
  final Value<String> name;
  final Value<double> amount;
  final Value<String?> cycle;
  final Value<DateTime?> nextDueDate;
  final Value<String?> memo;
  final Value<String?> syncId;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> isSynced;
  const DbFixedCostsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.cycle = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.memo = const Value.absent(),
    this.syncId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
  });
  DbFixedCostsCompanion.insert({
    this.id = const Value.absent(),
    required int accountId,
    required String name,
    required double amount,
    this.cycle = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.memo = const Value.absent(),
    this.syncId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
  }) : accountId = Value(accountId),
       name = Value(name),
       amount = Value(amount);
  static Insertable<DbFixedCost> custom({
    Expression<int>? id,
    Expression<int>? accountId,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? cycle,
    Expression<DateTime>? nextDueDate,
    Expression<String>? memo,
    Expression<String>? syncId,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? isSynced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (cycle != null) 'cycle': cycle,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (memo != null) 'memo': memo,
      if (syncId != null) 'sync_id': syncId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isSynced != null) 'is_synced': isSynced,
    });
  }

  DbFixedCostsCompanion copyWith({
    Value<int>? id,
    Value<int>? accountId,
    Value<String>? name,
    Value<double>? amount,
    Value<String?>? cycle,
    Value<DateTime?>? nextDueDate,
    Value<String?>? memo,
    Value<String?>? syncId,
    Value<DateTime?>? updatedAt,
    Value<bool>? isDeleted,
    Value<bool>? isSynced,
  }) {
    return DbFixedCostsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      cycle: cycle ?? this.cycle,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      memo: memo ?? this.memo,
      syncId: syncId ?? this.syncId,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (cycle.present) {
      map['cycle'] = Variable<String>(cycle.value);
    }
    if (nextDueDate.present) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbFixedCostsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('cycle: $cycle, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('memo: $memo, ')
          ..write('syncId: $syncId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }
}

class $DbRootMemosTable extends DbRootMemos
    with TableInfo<$DbRootMemosTable, DbRootMemo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbRootMemosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    createdAt,
    updatedAt,
    isPinned,
    color,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_root_memos';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbRootMemo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbRootMemo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbRootMemo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $DbRootMemosTable createAlias(String alias) {
    return $DbRootMemosTable(attachedDatabase, alias);
  }
}

class DbRootMemo extends DataClass implements Insertable<DbRootMemo> {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final String? color;
  final int sortOrder;
  const DbRootMemo({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
    this.color,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_pinned'] = Variable<bool>(isPinned);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DbRootMemosCompanion toCompanion(bool nullToAbsent) {
    return DbRootMemosCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isPinned: Value(isPinned),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      sortOrder: Value(sortOrder),
    );
  }

  factory DbRootMemo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbRootMemo(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      color: serializer.fromJson<String?>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isPinned': serializer.toJson<bool>(isPinned),
      'color': serializer.toJson<String?>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DbRootMemo copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    Value<String?> color = const Value.absent(),
    int? sortOrder,
  }) => DbRootMemo(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isPinned: isPinned ?? this.isPinned,
    color: color.present ? color.value : this.color,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  DbRootMemo copyWithCompanion(DbRootMemosCompanion data) {
    return DbRootMemo(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbRootMemo(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPinned: $isPinned, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    createdAt,
    updatedAt,
    isPinned,
    color,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbRootMemo &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isPinned == this.isPinned &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder);
}

class DbRootMemosCompanion extends UpdateCompanion<DbRootMemo> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isPinned;
  final Value<String?> color;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const DbRootMemosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbRootMemosCompanion.insert({
    required String id,
    required String title,
    required String content,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       content = Value(content);
  static Insertable<DbRootMemo> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isPinned,
    Expression<String>? color,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isPinned != null) 'is_pinned': isPinned,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbRootMemosCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isPinned,
    Value<String?>? color,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return DbRootMemosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbRootMemosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isPinned: $isPinned, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbIdempotencyKeysTable extends DbIdempotencyKeys
    with TableInfo<$DbIdempotencyKeysTable, DbIdempotencyKey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbIdempotencyKeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationKeyMeta = const VerificationMeta(
    'operationKey',
  );
  @override
  late final GeneratedColumn<String> operationKey = GeneratedColumn<String>(
    'operation_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationKey,
    result,
    createdAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_idempotency_keys';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbIdempotencyKey> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_key')) {
      context.handle(
        _operationKeyMeta,
        operationKey.isAcceptableOrUnknown(
          data['operation_key']!,
          _operationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationKeyMeta);
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationKey};
  @override
  DbIdempotencyKey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbIdempotencyKey(
      operationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_key'],
      )!,
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $DbIdempotencyKeysTable createAlias(String alias) {
    return $DbIdempotencyKeysTable(attachedDatabase, alias);
  }
}

class DbIdempotencyKey extends DataClass
    implements Insertable<DbIdempotencyKey> {
  final String operationKey;
  final String? result;
  final DateTime createdAt;
  final DateTime expiresAt;
  const DbIdempotencyKey({
    required this.operationKey,
    this.result,
    required this.createdAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_key'] = Variable<String>(operationKey);
    if (!nullToAbsent || result != null) {
      map['result'] = Variable<String>(result);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  DbIdempotencyKeysCompanion toCompanion(bool nullToAbsent) {
    return DbIdempotencyKeysCompanion(
      operationKey: Value(operationKey),
      result: result == null && nullToAbsent
          ? const Value.absent()
          : Value(result),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory DbIdempotencyKey.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbIdempotencyKey(
      operationKey: serializer.fromJson<String>(json['operationKey']),
      result: serializer.fromJson<String?>(json['result']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationKey': serializer.toJson<String>(operationKey),
      'result': serializer.toJson<String?>(result),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  DbIdempotencyKey copyWith({
    String? operationKey,
    Value<String?> result = const Value.absent(),
    DateTime? createdAt,
    DateTime? expiresAt,
  }) => DbIdempotencyKey(
    operationKey: operationKey ?? this.operationKey,
    result: result.present ? result.value : this.result,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  DbIdempotencyKey copyWithCompanion(DbIdempotencyKeysCompanion data) {
    return DbIdempotencyKey(
      operationKey: data.operationKey.present
          ? data.operationKey.value
          : this.operationKey,
      result: data.result.present ? data.result.value : this.result,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbIdempotencyKey(')
          ..write('operationKey: $operationKey, ')
          ..write('result: $result, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(operationKey, result, createdAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbIdempotencyKey &&
          other.operationKey == this.operationKey &&
          other.result == this.result &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class DbIdempotencyKeysCompanion extends UpdateCompanion<DbIdempotencyKey> {
  final Value<String> operationKey;
  final Value<String?> result;
  final Value<DateTime> createdAt;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const DbIdempotencyKeysCompanion({
    this.operationKey = const Value.absent(),
    this.result = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbIdempotencyKeysCompanion.insert({
    required String operationKey,
    this.result = const Value.absent(),
    this.createdAt = const Value.absent(),
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : operationKey = Value(operationKey),
       expiresAt = Value(expiresAt);
  static Insertable<DbIdempotencyKey> custom({
    Expression<String>? operationKey,
    Expression<String>? result,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationKey != null) 'operation_key': operationKey,
      if (result != null) 'result': result,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbIdempotencyKeysCompanion copyWith({
    Value<String>? operationKey,
    Value<String?>? result,
    Value<DateTime>? createdAt,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return DbIdempotencyKeysCompanion(
      operationKey: operationKey ?? this.operationKey,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationKey.present) {
      map['operation_key'] = Variable<String>(operationKey.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbIdempotencyKeysCompanion(')
          ..write('operationKey: $operationKey, ')
          ..write('result: $result, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DbAccountsTable dbAccounts = $DbAccountsTable(this);
  late final $DbTransactionsTable dbTransactions = $DbTransactionsTable(this);
  late final $DbAssetsTable dbAssets = $DbAssetsTable(this);
  late final $DbFixedCostsTable dbFixedCosts = $DbFixedCostsTable(this);
  late final $DbRootMemosTable dbRootMemos = $DbRootMemosTable(this);
  late final $DbIdempotencyKeysTable dbIdempotencyKeys =
      $DbIdempotencyKeysTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dbAccounts,
    dbTransactions,
    dbAssets,
    dbFixedCosts,
    dbRootMemos,
    dbIdempotencyKeys,
  ];
}

typedef $$DbAccountsTableCreateCompanionBuilder =
    DbAccountsCompanion Function({
      Value<int> id,
      required String name,
      Value<DateTime> createdAt,
      Value<String?> syncId,
      Value<DateTime?> updatedAt,
      Value<bool> isDeleted,
      Value<bool> isSynced,
    });
typedef $$DbAccountsTableUpdateCompanionBuilder =
    DbAccountsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<String?> syncId,
      Value<DateTime?> updatedAt,
      Value<bool> isDeleted,
      Value<bool> isSynced,
    });

final class $$DbAccountsTableReferences
    extends BaseReferences<_$AppDatabase, $DbAccountsTable, DbAccount> {
  $$DbAccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DbTransactionsTable, List<DbTransaction>>
  _dbTransactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dbTransactions,
    aliasName: $_aliasNameGenerator(
      db.dbAccounts.id,
      db.dbTransactions.accountId,
    ),
  );

  $$DbTransactionsTableProcessedTableManager get dbTransactionsRefs {
    final manager = $$DbTransactionsTableTableManager(
      $_db,
      $_db.dbTransactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dbTransactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DbAssetsTable, List<DbAsset>> _dbAssetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.dbAssets,
    aliasName: $_aliasNameGenerator(db.dbAccounts.id, db.dbAssets.accountId),
  );

  $$DbAssetsTableProcessedTableManager get dbAssetsRefs {
    final manager = $$DbAssetsTableTableManager(
      $_db,
      $_db.dbAssets,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dbAssetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DbFixedCostsTable, List<DbFixedCost>>
  _dbFixedCostsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dbFixedCosts,
    aliasName: $_aliasNameGenerator(
      db.dbAccounts.id,
      db.dbFixedCosts.accountId,
    ),
  );

  $$DbFixedCostsTableProcessedTableManager get dbFixedCostsRefs {
    final manager = $$DbFixedCostsTableTableManager(
      $_db,
      $_db.dbFixedCosts,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dbFixedCostsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DbAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $DbAccountsTable> {
  $$DbAccountsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dbTransactionsRefs(
    Expression<bool> Function($$DbTransactionsTableFilterComposer f) f,
  ) {
    final $$DbTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbTransactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.dbTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dbAssetsRefs(
    Expression<bool> Function($$DbAssetsTableFilterComposer f) f,
  ) {
    final $$DbAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbAssets,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbAssetsTableFilterComposer(
            $db: $db,
            $table: $db.dbAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dbFixedCostsRefs(
    Expression<bool> Function($$DbFixedCostsTableFilterComposer f) f,
  ) {
    final $$DbFixedCostsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbFixedCosts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFixedCostsTableFilterComposer(
            $db: $db,
            $table: $db.dbFixedCosts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DbAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbAccountsTable> {
  $$DbAccountsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DbAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbAccountsTable> {
  $$DbAccountsTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  Expression<T> dbTransactionsRefs<T extends Object>(
    Expression<T> Function($$DbTransactionsTableAnnotationComposer a) f,
  ) {
    final $$DbTransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbTransactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbTransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.dbTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dbAssetsRefs<T extends Object>(
    Expression<T> Function($$DbAssetsTableAnnotationComposer a) f,
  ) {
    final $$DbAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbAssets,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.dbAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dbFixedCostsRefs<T extends Object>(
    Expression<T> Function($$DbFixedCostsTableAnnotationComposer a) f,
  ) {
    final $$DbFixedCostsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbFixedCosts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFixedCostsTableAnnotationComposer(
            $db: $db,
            $table: $db.dbFixedCosts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DbAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbAccountsTable,
          DbAccount,
          $$DbAccountsTableFilterComposer,
          $$DbAccountsTableOrderingComposer,
          $$DbAccountsTableAnnotationComposer,
          $$DbAccountsTableCreateCompanionBuilder,
          $$DbAccountsTableUpdateCompanionBuilder,
          (DbAccount, $$DbAccountsTableReferences),
          DbAccount,
          PrefetchHooks Function({
            bool dbTransactionsRefs,
            bool dbAssetsRefs,
            bool dbFixedCostsRefs,
          })
        > {
  $$DbAccountsTableTableManager(_$AppDatabase db, $DbAccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => DbAccountsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                syncId: syncId,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                isSynced: isSynced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => DbAccountsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                syncId: syncId,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                isSynced: isSynced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DbAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                dbTransactionsRefs = false,
                dbAssetsRefs = false,
                dbFixedCostsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (dbTransactionsRefs) db.dbTransactions,
                    if (dbAssetsRefs) db.dbAssets,
                    if (dbFixedCostsRefs) db.dbFixedCosts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (dbTransactionsRefs)
                        await $_getPrefetchedData<
                          DbAccount,
                          $DbAccountsTable,
                          DbTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$DbAccountsTableReferences
                              ._dbTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DbAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).dbTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dbAssetsRefs)
                        await $_getPrefetchedData<
                          DbAccount,
                          $DbAccountsTable,
                          DbAsset
                        >(
                          currentTable: table,
                          referencedTable: $$DbAccountsTableReferences
                              ._dbAssetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DbAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).dbAssetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dbFixedCostsRefs)
                        await $_getPrefetchedData<
                          DbAccount,
                          $DbAccountsTable,
                          DbFixedCost
                        >(
                          currentTable: table,
                          referencedTable: $$DbAccountsTableReferences
                              ._dbFixedCostsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DbAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).dbFixedCostsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DbAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbAccountsTable,
      DbAccount,
      $$DbAccountsTableFilterComposer,
      $$DbAccountsTableOrderingComposer,
      $$DbAccountsTableAnnotationComposer,
      $$DbAccountsTableCreateCompanionBuilder,
      $$DbAccountsTableUpdateCompanionBuilder,
      (DbAccount, $$DbAccountsTableReferences),
      DbAccount,
      PrefetchHooks Function({
        bool dbTransactionsRefs,
        bool dbAssetsRefs,
        bool dbFixedCostsRefs,
      })
    >;
typedef $$DbTransactionsTableCreateCompanionBuilder =
    DbTransactionsCompanion Function({
      required String id,
      required int accountId,
      required String type,
      Value<String> description,
      required double amount,
      Value<double?> cardChargedAmount,
      required DateTime date,
      Value<int> quantity,
      Value<double> unitPrice,
      Value<String> paymentMethod,
      Value<String> memo,
      Value<String?> store,
      Value<String> mainCategory,
      Value<String?> subCategory,
      Value<String?> detailCategory,
      Value<String?> location,
      Value<String?> supplier,
      Value<DateTime?> expiryDate,
      Value<String?> unit,
      Value<String> currency,
      Value<double> exchangeRate,
      Value<double?> originalAmount,
      Value<double> vatAmount,
      Value<String?> savingsAllocation,
      Value<int> isRefund,
      Value<String?> originalTransactionId,
      Value<String?> weatherJson,
      Value<String?> benefitJson,
      Value<String?> syncId,
      Value<DateTime?> updatedAt,
      Value<bool> isDeleted,
      Value<bool> isSynced,
      Value<String?> integrityHash,
      Value<int> rowid,
    });
typedef $$DbTransactionsTableUpdateCompanionBuilder =
    DbTransactionsCompanion Function({
      Value<String> id,
      Value<int> accountId,
      Value<String> type,
      Value<String> description,
      Value<double> amount,
      Value<double?> cardChargedAmount,
      Value<DateTime> date,
      Value<int> quantity,
      Value<double> unitPrice,
      Value<String> paymentMethod,
      Value<String> memo,
      Value<String?> store,
      Value<String> mainCategory,
      Value<String?> subCategory,
      Value<String?> detailCategory,
      Value<String?> location,
      Value<String?> supplier,
      Value<DateTime?> expiryDate,
      Value<String?> unit,
      Value<String> currency,
      Value<double> exchangeRate,
      Value<double?> originalAmount,
      Value<double> vatAmount,
      Value<String?> savingsAllocation,
      Value<int> isRefund,
      Value<String?> originalTransactionId,
      Value<String?> weatherJson,
      Value<String?> benefitJson,
      Value<String?> syncId,
      Value<DateTime?> updatedAt,
      Value<bool> isDeleted,
      Value<bool> isSynced,
      Value<String?> integrityHash,
      Value<int> rowid,
    });

final class $$DbTransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $DbTransactionsTable, DbTransaction> {
  $$DbTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DbAccountsTable _accountIdTable(_$AppDatabase db) =>
      db.dbAccounts.createAlias(
        $_aliasNameGenerator(db.dbTransactions.accountId, db.dbAccounts.id),
      );

  $$DbAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$DbAccountsTableTableManager(
      $_db,
      $_db.dbAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DbTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $DbTransactionsTable> {
  $$DbTransactionsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cardChargedAmount => $composableBuilder(
    column: $table.cardChargedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get store => $composableBuilder(
    column: $table.store,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mainCategory => $composableBuilder(
    column: $table.mainCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailCategory => $composableBuilder(
    column: $table.detailCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatAmount => $composableBuilder(
    column: $table.vatAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get savingsAllocation => $composableBuilder(
    column: $table.savingsAllocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isRefund => $composableBuilder(
    column: $table.isRefund,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTransactionId => $composableBuilder(
    column: $table.originalTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weatherJson => $composableBuilder(
    column: $table.weatherJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get benefitJson => $composableBuilder(
    column: $table.benefitJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get integrityHash => $composableBuilder(
    column: $table.integrityHash,
    builder: (column) => ColumnFilters(column),
  );

  $$DbAccountsTableFilterComposer get accountId {
    final $$DbAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.dbAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbAccountsTableFilterComposer(
            $db: $db,
            $table: $db.dbAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbTransactionsTable> {
  $$DbTransactionsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cardChargedAmount => $composableBuilder(
    column: $table.cardChargedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get store => $composableBuilder(
    column: $table.store,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mainCategory => $composableBuilder(
    column: $table.mainCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailCategory => $composableBuilder(
    column: $table.detailCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatAmount => $composableBuilder(
    column: $table.vatAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savingsAllocation => $composableBuilder(
    column: $table.savingsAllocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isRefund => $composableBuilder(
    column: $table.isRefund,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTransactionId => $composableBuilder(
    column: $table.originalTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weatherJson => $composableBuilder(
    column: $table.weatherJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get benefitJson => $composableBuilder(
    column: $table.benefitJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get integrityHash => $composableBuilder(
    column: $table.integrityHash,
    builder: (column) => ColumnOrderings(column),
  );

  $$DbAccountsTableOrderingComposer get accountId {
    final $$DbAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.dbAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.dbAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbTransactionsTable> {
  $$DbTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get cardChargedAmount => $composableBuilder(
    column: $table.cardChargedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get store =>
      $composableBuilder(column: $table.store, builder: (column) => column);

  GeneratedColumn<String> get mainCategory => $composableBuilder(
    column: $table.mainCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailCategory => $composableBuilder(
    column: $table.detailCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get supplier =>
      $composableBuilder(column: $table.supplier, builder: (column) => column);

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vatAmount =>
      $composableBuilder(column: $table.vatAmount, builder: (column) => column);

  GeneratedColumn<String> get savingsAllocation => $composableBuilder(
    column: $table.savingsAllocation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isRefund =>
      $composableBuilder(column: $table.isRefund, builder: (column) => column);

  GeneratedColumn<String> get originalTransactionId => $composableBuilder(
    column: $table.originalTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weatherJson => $composableBuilder(
    column: $table.weatherJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get benefitJson => $composableBuilder(
    column: $table.benefitJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get integrityHash => $composableBuilder(
    column: $table.integrityHash,
    builder: (column) => column,
  );

  $$DbAccountsTableAnnotationComposer get accountId {
    final $$DbAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.dbAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.dbAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbTransactionsTable,
          DbTransaction,
          $$DbTransactionsTableFilterComposer,
          $$DbTransactionsTableOrderingComposer,
          $$DbTransactionsTableAnnotationComposer,
          $$DbTransactionsTableCreateCompanionBuilder,
          $$DbTransactionsTableUpdateCompanionBuilder,
          (DbTransaction, $$DbTransactionsTableReferences),
          DbTransaction,
          PrefetchHooks Function({bool accountId})
        > {
  $$DbTransactionsTableTableManager(
    _$AppDatabase db,
    $DbTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbTransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double?> cardChargedAmount = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<String?> store = const Value.absent(),
                Value<String> mainCategory = const Value.absent(),
                Value<String?> subCategory = const Value.absent(),
                Value<String?> detailCategory = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> supplier = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<double?> originalAmount = const Value.absent(),
                Value<double> vatAmount = const Value.absent(),
                Value<String?> savingsAllocation = const Value.absent(),
                Value<int> isRefund = const Value.absent(),
                Value<String?> originalTransactionId = const Value.absent(),
                Value<String?> weatherJson = const Value.absent(),
                Value<String?> benefitJson = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> integrityHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DbTransactionsCompanion(
                id: id,
                accountId: accountId,
                type: type,
                description: description,
                amount: amount,
                cardChargedAmount: cardChargedAmount,
                date: date,
                quantity: quantity,
                unitPrice: unitPrice,
                paymentMethod: paymentMethod,
                memo: memo,
                store: store,
                mainCategory: mainCategory,
                subCategory: subCategory,
                detailCategory: detailCategory,
                location: location,
                supplier: supplier,
                expiryDate: expiryDate,
                unit: unit,
                currency: currency,
                exchangeRate: exchangeRate,
                originalAmount: originalAmount,
                vatAmount: vatAmount,
                savingsAllocation: savingsAllocation,
                isRefund: isRefund,
                originalTransactionId: originalTransactionId,
                weatherJson: weatherJson,
                benefitJson: benefitJson,
                syncId: syncId,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                isSynced: isSynced,
                integrityHash: integrityHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int accountId,
                required String type,
                Value<String> description = const Value.absent(),
                required double amount,
                Value<double?> cardChargedAmount = const Value.absent(),
                required DateTime date,
                Value<int> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<String?> store = const Value.absent(),
                Value<String> mainCategory = const Value.absent(),
                Value<String?> subCategory = const Value.absent(),
                Value<String?> detailCategory = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> supplier = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<double?> originalAmount = const Value.absent(),
                Value<double> vatAmount = const Value.absent(),
                Value<String?> savingsAllocation = const Value.absent(),
                Value<int> isRefund = const Value.absent(),
                Value<String?> originalTransactionId = const Value.absent(),
                Value<String?> weatherJson = const Value.absent(),
                Value<String?> benefitJson = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> integrityHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DbTransactionsCompanion.insert(
                id: id,
                accountId: accountId,
                type: type,
                description: description,
                amount: amount,
                cardChargedAmount: cardChargedAmount,
                date: date,
                quantity: quantity,
                unitPrice: unitPrice,
                paymentMethod: paymentMethod,
                memo: memo,
                store: store,
                mainCategory: mainCategory,
                subCategory: subCategory,
                detailCategory: detailCategory,
                location: location,
                supplier: supplier,
                expiryDate: expiryDate,
                unit: unit,
                currency: currency,
                exchangeRate: exchangeRate,
                originalAmount: originalAmount,
                vatAmount: vatAmount,
                savingsAllocation: savingsAllocation,
                isRefund: isRefund,
                originalTransactionId: originalTransactionId,
                weatherJson: weatherJson,
                benefitJson: benefitJson,
                syncId: syncId,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                isSynced: isSynced,
                integrityHash: integrityHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DbTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$DbTransactionsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn:
                                    $$DbTransactionsTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$DbTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbTransactionsTable,
      DbTransaction,
      $$DbTransactionsTableFilterComposer,
      $$DbTransactionsTableOrderingComposer,
      $$DbTransactionsTableAnnotationComposer,
      $$DbTransactionsTableCreateCompanionBuilder,
      $$DbTransactionsTableUpdateCompanionBuilder,
      (DbTransaction, $$DbTransactionsTableReferences),
      DbTransaction,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$DbAssetsTableCreateCompanionBuilder =
    DbAssetsCompanion Function({
      Value<int> id,
      required int accountId,
      Value<String?> category,
      required String name,
      required double amount,
      Value<String?> location,
      Value<String?> memo,
      Value<DateTime?> updatedAt,
      Value<String?> syncId,
      Value<bool> isDeleted,
      Value<bool> isSynced,
    });
typedef $$DbAssetsTableUpdateCompanionBuilder =
    DbAssetsCompanion Function({
      Value<int> id,
      Value<int> accountId,
      Value<String?> category,
      Value<String> name,
      Value<double> amount,
      Value<String?> location,
      Value<String?> memo,
      Value<DateTime?> updatedAt,
      Value<String?> syncId,
      Value<bool> isDeleted,
      Value<bool> isSynced,
    });

final class $$DbAssetsTableReferences
    extends BaseReferences<_$AppDatabase, $DbAssetsTable, DbAsset> {
  $$DbAssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DbAccountsTable _accountIdTable(_$AppDatabase db) =>
      db.dbAccounts.createAlias(
        $_aliasNameGenerator(db.dbAssets.accountId, db.dbAccounts.id),
      );

  $$DbAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$DbAccountsTableTableManager(
      $_db,
      $_db.dbAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DbAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $DbAssetsTable> {
  $$DbAssetsTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  $$DbAccountsTableFilterComposer get accountId {
    final $$DbAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.dbAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbAccountsTableFilterComposer(
            $db: $db,
            $table: $db.dbAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbAssetsTable> {
  $$DbAssetsTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  $$DbAccountsTableOrderingComposer get accountId {
    final $$DbAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.dbAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.dbAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbAssetsTable> {
  $$DbAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$DbAccountsTableAnnotationComposer get accountId {
    final $$DbAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.dbAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.dbAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbAssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbAssetsTable,
          DbAsset,
          $$DbAssetsTableFilterComposer,
          $$DbAssetsTableOrderingComposer,
          $$DbAssetsTableAnnotationComposer,
          $$DbAssetsTableCreateCompanionBuilder,
          $$DbAssetsTableUpdateCompanionBuilder,
          (DbAsset, $$DbAssetsTableReferences),
          DbAsset,
          PrefetchHooks Function({bool accountId})
        > {
  $$DbAssetsTableTableManager(_$AppDatabase db, $DbAssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => DbAssetsCompanion(
                id: id,
                accountId: accountId,
                category: category,
                name: name,
                amount: amount,
                location: location,
                memo: memo,
                updatedAt: updatedAt,
                syncId: syncId,
                isDeleted: isDeleted,
                isSynced: isSynced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int accountId,
                Value<String?> category = const Value.absent(),
                required String name,
                required double amount,
                Value<String?> location = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => DbAssetsCompanion.insert(
                id: id,
                accountId: accountId,
                category: category,
                name: name,
                amount: amount,
                location: location,
                memo: memo,
                updatedAt: updatedAt,
                syncId: syncId,
                isDeleted: isDeleted,
                isSynced: isSynced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DbAssetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$DbAssetsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$DbAssetsTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$DbAssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbAssetsTable,
      DbAsset,
      $$DbAssetsTableFilterComposer,
      $$DbAssetsTableOrderingComposer,
      $$DbAssetsTableAnnotationComposer,
      $$DbAssetsTableCreateCompanionBuilder,
      $$DbAssetsTableUpdateCompanionBuilder,
      (DbAsset, $$DbAssetsTableReferences),
      DbAsset,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$DbFixedCostsTableCreateCompanionBuilder =
    DbFixedCostsCompanion Function({
      Value<int> id,
      required int accountId,
      required String name,
      required double amount,
      Value<String?> cycle,
      Value<DateTime?> nextDueDate,
      Value<String?> memo,
      Value<String?> syncId,
      Value<DateTime?> updatedAt,
      Value<bool> isDeleted,
      Value<bool> isSynced,
    });
typedef $$DbFixedCostsTableUpdateCompanionBuilder =
    DbFixedCostsCompanion Function({
      Value<int> id,
      Value<int> accountId,
      Value<String> name,
      Value<double> amount,
      Value<String?> cycle,
      Value<DateTime?> nextDueDate,
      Value<String?> memo,
      Value<String?> syncId,
      Value<DateTime?> updatedAt,
      Value<bool> isDeleted,
      Value<bool> isSynced,
    });

final class $$DbFixedCostsTableReferences
    extends BaseReferences<_$AppDatabase, $DbFixedCostsTable, DbFixedCost> {
  $$DbFixedCostsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DbAccountsTable _accountIdTable(_$AppDatabase db) =>
      db.dbAccounts.createAlias(
        $_aliasNameGenerator(db.dbFixedCosts.accountId, db.dbAccounts.id),
      );

  $$DbAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$DbAccountsTableTableManager(
      $_db,
      $_db.dbAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DbFixedCostsTableFilterComposer
    extends Composer<_$AppDatabase, $DbFixedCostsTable> {
  $$DbFixedCostsTableFilterComposer({
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

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycle => $composableBuilder(
    column: $table.cycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  $$DbAccountsTableFilterComposer get accountId {
    final $$DbAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.dbAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbAccountsTableFilterComposer(
            $db: $db,
            $table: $db.dbAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbFixedCostsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbFixedCostsTable> {
  $$DbFixedCostsTableOrderingComposer({
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

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycle => $composableBuilder(
    column: $table.cycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  $$DbAccountsTableOrderingComposer get accountId {
    final $$DbAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.dbAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.dbAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbFixedCostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbFixedCostsTable> {
  $$DbFixedCostsTableAnnotationComposer({
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

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get cycle =>
      $composableBuilder(column: $table.cycle, builder: (column) => column);

  GeneratedColumn<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$DbAccountsTableAnnotationComposer get accountId {
    final $$DbAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.dbAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.dbAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbFixedCostsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbFixedCostsTable,
          DbFixedCost,
          $$DbFixedCostsTableFilterComposer,
          $$DbFixedCostsTableOrderingComposer,
          $$DbFixedCostsTableAnnotationComposer,
          $$DbFixedCostsTableCreateCompanionBuilder,
          $$DbFixedCostsTableUpdateCompanionBuilder,
          (DbFixedCost, $$DbFixedCostsTableReferences),
          DbFixedCost,
          PrefetchHooks Function({bool accountId})
        > {
  $$DbFixedCostsTableTableManager(_$AppDatabase db, $DbFixedCostsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbFixedCostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbFixedCostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbFixedCostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> cycle = const Value.absent(),
                Value<DateTime?> nextDueDate = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => DbFixedCostsCompanion(
                id: id,
                accountId: accountId,
                name: name,
                amount: amount,
                cycle: cycle,
                nextDueDate: nextDueDate,
                memo: memo,
                syncId: syncId,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                isSynced: isSynced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int accountId,
                required String name,
                required double amount,
                Value<String?> cycle = const Value.absent(),
                Value<DateTime?> nextDueDate = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => DbFixedCostsCompanion.insert(
                id: id,
                accountId: accountId,
                name: name,
                amount: amount,
                cycle: cycle,
                nextDueDate: nextDueDate,
                memo: memo,
                syncId: syncId,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                isSynced: isSynced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DbFixedCostsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$DbFixedCostsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$DbFixedCostsTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$DbFixedCostsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbFixedCostsTable,
      DbFixedCost,
      $$DbFixedCostsTableFilterComposer,
      $$DbFixedCostsTableOrderingComposer,
      $$DbFixedCostsTableAnnotationComposer,
      $$DbFixedCostsTableCreateCompanionBuilder,
      $$DbFixedCostsTableUpdateCompanionBuilder,
      (DbFixedCost, $$DbFixedCostsTableReferences),
      DbFixedCost,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$DbRootMemosTableCreateCompanionBuilder =
    DbRootMemosCompanion Function({
      required String id,
      required String title,
      required String content,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isPinned,
      Value<String?> color,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$DbRootMemosTableUpdateCompanionBuilder =
    DbRootMemosCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isPinned,
      Value<String?> color,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$DbRootMemosTableFilterComposer
    extends Composer<_$AppDatabase, $DbRootMemosTable> {
  $$DbRootMemosTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DbRootMemosTableOrderingComposer
    extends Composer<_$AppDatabase, $DbRootMemosTable> {
  $$DbRootMemosTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DbRootMemosTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbRootMemosTable> {
  $$DbRootMemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$DbRootMemosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbRootMemosTable,
          DbRootMemo,
          $$DbRootMemosTableFilterComposer,
          $$DbRootMemosTableOrderingComposer,
          $$DbRootMemosTableAnnotationComposer,
          $$DbRootMemosTableCreateCompanionBuilder,
          $$DbRootMemosTableUpdateCompanionBuilder,
          (
            DbRootMemo,
            BaseReferences<_$AppDatabase, $DbRootMemosTable, DbRootMemo>,
          ),
          DbRootMemo,
          PrefetchHooks Function()
        > {
  $$DbRootMemosTableTableManager(_$AppDatabase db, $DbRootMemosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbRootMemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbRootMemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbRootMemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DbRootMemosCompanion(
                id: id,
                title: title,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPinned: isPinned,
                color: color,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String content,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DbRootMemosCompanion.insert(
                id: id,
                title: title,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isPinned: isPinned,
                color: color,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DbRootMemosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbRootMemosTable,
      DbRootMemo,
      $$DbRootMemosTableFilterComposer,
      $$DbRootMemosTableOrderingComposer,
      $$DbRootMemosTableAnnotationComposer,
      $$DbRootMemosTableCreateCompanionBuilder,
      $$DbRootMemosTableUpdateCompanionBuilder,
      (
        DbRootMemo,
        BaseReferences<_$AppDatabase, $DbRootMemosTable, DbRootMemo>,
      ),
      DbRootMemo,
      PrefetchHooks Function()
    >;
typedef $$DbIdempotencyKeysTableCreateCompanionBuilder =
    DbIdempotencyKeysCompanion Function({
      required String operationKey,
      Value<String?> result,
      Value<DateTime> createdAt,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$DbIdempotencyKeysTableUpdateCompanionBuilder =
    DbIdempotencyKeysCompanion Function({
      Value<String> operationKey,
      Value<String?> result,
      Value<DateTime> createdAt,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

class $$DbIdempotencyKeysTableFilterComposer
    extends Composer<_$AppDatabase, $DbIdempotencyKeysTable> {
  $$DbIdempotencyKeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationKey => $composableBuilder(
    column: $table.operationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DbIdempotencyKeysTableOrderingComposer
    extends Composer<_$AppDatabase, $DbIdempotencyKeysTable> {
  $$DbIdempotencyKeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationKey => $composableBuilder(
    column: $table.operationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DbIdempotencyKeysTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbIdempotencyKeysTable> {
  $$DbIdempotencyKeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationKey => $composableBuilder(
    column: $table.operationKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$DbIdempotencyKeysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbIdempotencyKeysTable,
          DbIdempotencyKey,
          $$DbIdempotencyKeysTableFilterComposer,
          $$DbIdempotencyKeysTableOrderingComposer,
          $$DbIdempotencyKeysTableAnnotationComposer,
          $$DbIdempotencyKeysTableCreateCompanionBuilder,
          $$DbIdempotencyKeysTableUpdateCompanionBuilder,
          (
            DbIdempotencyKey,
            BaseReferences<
              _$AppDatabase,
              $DbIdempotencyKeysTable,
              DbIdempotencyKey
            >,
          ),
          DbIdempotencyKey,
          PrefetchHooks Function()
        > {
  $$DbIdempotencyKeysTableTableManager(
    _$AppDatabase db,
    $DbIdempotencyKeysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbIdempotencyKeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbIdempotencyKeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbIdempotencyKeysTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> operationKey = const Value.absent(),
                Value<String?> result = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DbIdempotencyKeysCompanion(
                operationKey: operationKey,
                result: result,
                createdAt: createdAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationKey,
                Value<String?> result = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => DbIdempotencyKeysCompanion.insert(
                operationKey: operationKey,
                result: result,
                createdAt: createdAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DbIdempotencyKeysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbIdempotencyKeysTable,
      DbIdempotencyKey,
      $$DbIdempotencyKeysTableFilterComposer,
      $$DbIdempotencyKeysTableOrderingComposer,
      $$DbIdempotencyKeysTableAnnotationComposer,
      $$DbIdempotencyKeysTableCreateCompanionBuilder,
      $$DbIdempotencyKeysTableUpdateCompanionBuilder,
      (
        DbIdempotencyKey,
        BaseReferences<
          _$AppDatabase,
          $DbIdempotencyKeysTable,
          DbIdempotencyKey
        >,
      ),
      DbIdempotencyKey,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DbAccountsTableTableManager get dbAccounts =>
      $$DbAccountsTableTableManager(_db, _db.dbAccounts);
  $$DbTransactionsTableTableManager get dbTransactions =>
      $$DbTransactionsTableTableManager(_db, _db.dbTransactions);
  $$DbAssetsTableTableManager get dbAssets =>
      $$DbAssetsTableTableManager(_db, _db.dbAssets);
  $$DbFixedCostsTableTableManager get dbFixedCosts =>
      $$DbFixedCostsTableTableManager(_db, _db.dbFixedCosts);
  $$DbRootMemosTableTableManager get dbRootMemos =>
      $$DbRootMemosTableTableManager(_db, _db.dbRootMemos);
  $$DbIdempotencyKeysTableTableManager get dbIdempotencyKeys =>
      $$DbIdempotencyKeysTableTableManager(_db, _db.dbIdempotencyKeys);
}
