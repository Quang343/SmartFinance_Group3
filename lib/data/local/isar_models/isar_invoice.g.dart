// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_invoice.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarInvoiceCollection on Isar {
  IsarCollection<IsarInvoice> get isarInvoices => this.collection();
}

const IsarInvoiceSchema = CollectionSchema(
  name: r'Invoice',
  id: -341399436017629,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'imagePath': PropertySchema(
      id: 1,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'invoiceNumber': PropertySchema(
      id: 2,
      name: r'invoiceNumber',
      type: IsarType.string,
    ),
    r'issuedDate': PropertySchema(
      id: 3,
      name: r'issuedDate',
      type: IsarType.dateTime,
    ),
    r'ocrConfidence': PropertySchema(
      id: 4,
      name: r'ocrConfidence',
      type: IsarType.double,
    ),
    r'ocrStatus': PropertySchema(
      id: 5,
      name: r'ocrStatus',
      type: IsarType.string,
    ),
    r'partnerName': PropertySchema(
      id: 6,
      name: r'partnerName',
      type: IsarType.string,
    ),
    r'partnerTaxCode': PropertySchema(
      id: 7,
      name: r'partnerTaxCode',
      type: IsarType.string,
    ),
    r'subtotal': PropertySchema(
      id: 8,
      name: r'subtotal',
      type: IsarType.long,
    ),
    r'totalAmount': PropertySchema(
      id: 9,
      name: r'totalAmount',
      type: IsarType.long,
    ),
    r'type': PropertySchema(
      id: 10,
      name: r'type',
      type: IsarType.string,
    ),
    r'uid': PropertySchema(
      id: 11,
      name: r'uid',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 12,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'vatAmount': PropertySchema(
      id: 13,
      name: r'vatAmount',
      type: IsarType.long,
    ),
    r'vatRate': PropertySchema(
      id: 14,
      name: r'vatRate',
      type: IsarType.long,
    )
  },
  estimateSize: _isarInvoiceEstimateSize,
  serialize: _isarInvoiceSerialize,
  deserialize: _isarInvoiceDeserialize,
  deserializeProp: _isarInvoiceDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'invoiceNumber': IndexSchema(
      id: -6231821761165001198,
      name: r'invoiceNumber',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'invoiceNumber',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'partnerTaxCode': IndexSchema(
      id: 7814549587980781845,
      name: r'partnerTaxCode',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'partnerTaxCode',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'ocrStatus': IndexSchema(
      id: -2881715995472735260,
      name: r'ocrStatus',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ocrStatus',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'type': IndexSchema(
      id: 5117122708147080838,
      name: r'type',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'issuedDate': IndexSchema(
      id: 5154051486524315182,
      name: r'issuedDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'issuedDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarInvoiceGetId,
  getLinks: _isarInvoiceGetLinks,
  attach: _isarInvoiceAttach,
  version: '3.1.0+1',
);

int _isarInvoiceEstimateSize(
  IsarInvoice object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.imagePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.invoiceNumber.length * 3;
  bytesCount += 3 + object.ocrStatus.length * 3;
  bytesCount += 3 + object.partnerName.length * 3;
  bytesCount += 3 + object.partnerTaxCode.length * 3;
  bytesCount += 3 + object.type.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _isarInvoiceSerialize(
  IsarInvoice object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.imagePath);
  writer.writeString(offsets[2], object.invoiceNumber);
  writer.writeDateTime(offsets[3], object.issuedDate);
  writer.writeDouble(offsets[4], object.ocrConfidence);
  writer.writeString(offsets[5], object.ocrStatus);
  writer.writeString(offsets[6], object.partnerName);
  writer.writeString(offsets[7], object.partnerTaxCode);
  writer.writeLong(offsets[8], object.subtotal);
  writer.writeLong(offsets[9], object.totalAmount);
  writer.writeString(offsets[10], object.type);
  writer.writeString(offsets[11], object.uid);
  writer.writeDateTime(offsets[12], object.updatedAt);
  writer.writeLong(offsets[13], object.vatAmount);
  writer.writeLong(offsets[14], object.vatRate);
}

IsarInvoice _isarInvoiceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarInvoice();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.imagePath = reader.readStringOrNull(offsets[1]);
  object.invoiceNumber = reader.readString(offsets[2]);
  object.issuedDate = reader.readDateTime(offsets[3]);
  object.ocrConfidence = reader.readDoubleOrNull(offsets[4]);
  object.ocrStatus = reader.readString(offsets[5]);
  object.partnerName = reader.readString(offsets[6]);
  object.partnerTaxCode = reader.readString(offsets[7]);
  object.subtotal = reader.readLong(offsets[8]);
  object.totalAmount = reader.readLong(offsets[9]);
  object.type = reader.readString(offsets[10]);
  object.uid = reader.readString(offsets[11]);
  object.updatedAt = reader.readDateTime(offsets[12]);
  object.vatAmount = reader.readLong(offsets[13]);
  object.vatRate = reader.readLong(offsets[14]);
  return object;
}

P _isarInvoiceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarInvoiceGetId(IsarInvoice object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarInvoiceGetLinks(IsarInvoice object) {
  return [];
}

void _isarInvoiceAttach(
    IsarCollection<dynamic> col, Id id, IsarInvoice object) {
  object.id = id;
}

extension IsarInvoiceByIndex on IsarCollection<IsarInvoice> {
  Future<IsarInvoice?> getByUid(String uid) {
    return getByIndex(r'uid', [uid]);
  }

  IsarInvoice? getByUidSync(String uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<IsarInvoice?>> getAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<IsarInvoice?> getAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(IsarInvoice object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(IsarInvoice object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<IsarInvoice> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(List<IsarInvoice> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }

  Future<IsarInvoice?> getByInvoiceNumber(String invoiceNumber) {
    return getByIndex(r'invoiceNumber', [invoiceNumber]);
  }

  IsarInvoice? getByInvoiceNumberSync(String invoiceNumber) {
    return getByIndexSync(r'invoiceNumber', [invoiceNumber]);
  }

  Future<bool> deleteByInvoiceNumber(String invoiceNumber) {
    return deleteByIndex(r'invoiceNumber', [invoiceNumber]);
  }

  bool deleteByInvoiceNumberSync(String invoiceNumber) {
    return deleteByIndexSync(r'invoiceNumber', [invoiceNumber]);
  }

  Future<List<IsarInvoice?>> getAllByInvoiceNumber(
      List<String> invoiceNumberValues) {
    final values = invoiceNumberValues.map((e) => [e]).toList();
    return getAllByIndex(r'invoiceNumber', values);
  }

  List<IsarInvoice?> getAllByInvoiceNumberSync(
      List<String> invoiceNumberValues) {
    final values = invoiceNumberValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'invoiceNumber', values);
  }

  Future<int> deleteAllByInvoiceNumber(List<String> invoiceNumberValues) {
    final values = invoiceNumberValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'invoiceNumber', values);
  }

  int deleteAllByInvoiceNumberSync(List<String> invoiceNumberValues) {
    final values = invoiceNumberValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'invoiceNumber', values);
  }

  Future<Id> putByInvoiceNumber(IsarInvoice object) {
    return putByIndex(r'invoiceNumber', object);
  }

  Id putByInvoiceNumberSync(IsarInvoice object, {bool saveLinks = true}) {
    return putByIndexSync(r'invoiceNumber', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByInvoiceNumber(List<IsarInvoice> objects) {
    return putAllByIndex(r'invoiceNumber', objects);
  }

  List<Id> putAllByInvoiceNumberSync(List<IsarInvoice> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'invoiceNumber', objects, saveLinks: saveLinks);
  }
}

extension IsarInvoiceQueryWhereSort
    on QueryBuilder<IsarInvoice, IsarInvoice, QWhere> {
  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhere> anyIssuedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'issuedDate'),
      );
    });
  }
}

extension IsarInvoiceQueryWhere
    on QueryBuilder<IsarInvoice, IsarInvoice, QWhereClause> {
  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> uidEqualTo(
      String uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid',
        value: [uid],
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> uidNotEqualTo(
      String uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause>
      invoiceNumberEqualTo(String invoiceNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'invoiceNumber',
        value: [invoiceNumber],
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause>
      invoiceNumberNotEqualTo(String invoiceNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceNumber',
              lower: [],
              upper: [invoiceNumber],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceNumber',
              lower: [invoiceNumber],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceNumber',
              lower: [invoiceNumber],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'invoiceNumber',
              lower: [],
              upper: [invoiceNumber],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause>
      partnerTaxCodeEqualTo(String partnerTaxCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'partnerTaxCode',
        value: [partnerTaxCode],
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause>
      partnerTaxCodeNotEqualTo(String partnerTaxCode) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partnerTaxCode',
              lower: [],
              upper: [partnerTaxCode],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partnerTaxCode',
              lower: [partnerTaxCode],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partnerTaxCode',
              lower: [partnerTaxCode],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'partnerTaxCode',
              lower: [],
              upper: [partnerTaxCode],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> ocrStatusEqualTo(
      String ocrStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ocrStatus',
        value: [ocrStatus],
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> ocrStatusNotEqualTo(
      String ocrStatus) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ocrStatus',
              lower: [],
              upper: [ocrStatus],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ocrStatus',
              lower: [ocrStatus],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ocrStatus',
              lower: [ocrStatus],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ocrStatus',
              lower: [],
              upper: [ocrStatus],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> typeEqualTo(
      String type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type',
        value: [type],
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> typeNotEqualTo(
      String type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> issuedDateEqualTo(
      DateTime issuedDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'issuedDate',
        value: [issuedDate],
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause>
      issuedDateNotEqualTo(DateTime issuedDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'issuedDate',
              lower: [],
              upper: [issuedDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'issuedDate',
              lower: [issuedDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'issuedDate',
              lower: [issuedDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'issuedDate',
              lower: [],
              upper: [issuedDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause>
      issuedDateGreaterThan(
    DateTime issuedDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'issuedDate',
        lower: [issuedDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> issuedDateLessThan(
    DateTime issuedDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'issuedDate',
        lower: [],
        upper: [issuedDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterWhereClause> issuedDateBetween(
    DateTime lowerIssuedDate,
    DateTime upperIssuedDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'issuedDate',
        lower: [lowerIssuedDate],
        includeLower: includeLower,
        upper: [upperIssuedDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarInvoiceQueryFilter
    on QueryBuilder<IsarInvoice, IsarInvoice, QFilterCondition> {
  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      invoiceNumberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      invoiceNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      invoiceNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      invoiceNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invoiceNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      invoiceNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      invoiceNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      invoiceNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      invoiceNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'invoiceNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      invoiceNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      invoiceNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'invoiceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      issuedDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'issuedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      issuedDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'issuedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      issuedDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'issuedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      issuedDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'issuedDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrConfidenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ocrConfidence',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrConfidenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ocrConfidence',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrConfidenceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ocrConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrConfidenceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ocrConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrConfidenceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ocrConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrConfidenceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ocrConfidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrStatusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ocrStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrStatusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ocrStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrStatusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ocrStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrStatusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ocrStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ocrStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ocrStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ocrStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ocrStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ocrStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      ocrStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ocrStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partnerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partnerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partnerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partnerName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'partnerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'partnerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'partnerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'partnerName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partnerName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'partnerName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerTaxCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partnerTaxCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerTaxCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partnerTaxCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerTaxCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partnerTaxCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerTaxCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partnerTaxCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerTaxCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'partnerTaxCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerTaxCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'partnerTaxCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerTaxCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'partnerTaxCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerTaxCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'partnerTaxCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerTaxCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partnerTaxCode',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      partnerTaxCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'partnerTaxCode',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> subtotalEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtotal',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      subtotalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subtotal',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      subtotalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subtotal',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> subtotalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subtotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      totalAmountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      totalAmountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      totalAmountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      totalAmountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> uidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> uidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> uidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> uidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      vatAmountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vatAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      vatAmountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vatAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      vatAmountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vatAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      vatAmountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vatAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> vatRateEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vatRate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition>
      vatRateGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vatRate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> vatRateLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vatRate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> vatRateBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vatRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarInvoiceQueryObject
    on QueryBuilder<IsarInvoice, IsarInvoice, QFilterCondition> {}

extension IsarInvoiceQueryLinks
    on QueryBuilder<IsarInvoice, IsarInvoice, QFilterCondition> {}

extension IsarInvoiceQuerySortBy
    on QueryBuilder<IsarInvoice, IsarInvoice, QSortBy> {
  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy>
      sortByInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByIssuedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issuedDate', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByIssuedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issuedDate', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByOcrConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrConfidence', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy>
      sortByOcrConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrConfidence', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByOcrStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrStatus', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByOcrStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrStatus', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByPartnerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partnerName', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByPartnerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partnerName', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByPartnerTaxCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partnerTaxCode', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy>
      sortByPartnerTaxCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partnerTaxCode', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByVatAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByVatAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByVatRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatRate', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> sortByVatRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatRate', Sort.desc);
    });
  }
}

extension IsarInvoiceQuerySortThenBy
    on QueryBuilder<IsarInvoice, IsarInvoice, QSortThenBy> {
  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy>
      thenByInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByIssuedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issuedDate', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByIssuedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'issuedDate', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByOcrConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrConfidence', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy>
      thenByOcrConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrConfidence', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByOcrStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrStatus', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByOcrStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrStatus', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByPartnerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partnerName', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByPartnerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partnerName', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByPartnerTaxCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partnerTaxCode', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy>
      thenByPartnerTaxCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partnerTaxCode', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenBySubtotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtotal', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByVatAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatAmount', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByVatAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatAmount', Sort.desc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByVatRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatRate', Sort.asc);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QAfterSortBy> thenByVatRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vatRate', Sort.desc);
    });
  }
}

extension IsarInvoiceQueryWhereDistinct
    on QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> {
  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByImagePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByInvoiceNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invoiceNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByIssuedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'issuedDate');
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByOcrConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ocrConfidence');
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByOcrStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ocrStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByPartnerName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partnerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByPartnerTaxCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partnerTaxCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctBySubtotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtotal');
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAmount');
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByVatAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vatAmount');
    });
  }

  QueryBuilder<IsarInvoice, IsarInvoice, QDistinct> distinctByVatRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vatRate');
    });
  }
}

extension IsarInvoiceQueryProperty
    on QueryBuilder<IsarInvoice, IsarInvoice, QQueryProperty> {
  QueryBuilder<IsarInvoice, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarInvoice, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarInvoice, String?, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<IsarInvoice, String, QQueryOperations> invoiceNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoiceNumber');
    });
  }

  QueryBuilder<IsarInvoice, DateTime, QQueryOperations> issuedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'issuedDate');
    });
  }

  QueryBuilder<IsarInvoice, double?, QQueryOperations> ocrConfidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ocrConfidence');
    });
  }

  QueryBuilder<IsarInvoice, String, QQueryOperations> ocrStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ocrStatus');
    });
  }

  QueryBuilder<IsarInvoice, String, QQueryOperations> partnerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partnerName');
    });
  }

  QueryBuilder<IsarInvoice, String, QQueryOperations> partnerTaxCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partnerTaxCode');
    });
  }

  QueryBuilder<IsarInvoice, int, QQueryOperations> subtotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtotal');
    });
  }

  QueryBuilder<IsarInvoice, int, QQueryOperations> totalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAmount');
    });
  }

  QueryBuilder<IsarInvoice, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<IsarInvoice, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<IsarInvoice, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<IsarInvoice, int, QQueryOperations> vatAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vatAmount');
    });
  }

  QueryBuilder<IsarInvoice, int, QQueryOperations> vatRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vatRate');
    });
  }
}
