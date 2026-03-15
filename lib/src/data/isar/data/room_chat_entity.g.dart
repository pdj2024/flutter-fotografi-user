// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_chat_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRoomChatEntityCollection on Isar {
  IsarCollection<RoomChatEntity> get roomChatEntitys => this.collection();
}

const RoomChatEntitySchema = CollectionSchema(
  name: r'RoomChatEntity',
  id: -2886589375896824728,
  properties: {
    r'countStatusReceived': PropertySchema(
      id: 0,
      name: r'countStatusReceived',
      type: IsarType.long,
    ),
    r'countStatusSent': PropertySchema(
      id: 1,
      name: r'countStatusSent',
      type: IsarType.long,
    ),
    r'idLawan': PropertySchema(
      id: 2,
      name: r'idLawan',
      type: IsarType.string,
    ),
    r'idMediaLawan': PropertySchema(
      id: 3,
      name: r'idMediaLawan',
      type: IsarType.string,
    ),
    r'lastMessage': PropertySchema(
      id: 4,
      name: r'lastMessage',
      type: IsarType.string,
    ),
    r'lastMessageAt': PropertySchema(
      id: 5,
      name: r'lastMessageAt',
      type: IsarType.dateTime,
    ),
    r'listIdMessageReceived': PropertySchema(
      id: 6,
      name: r'listIdMessageReceived',
      type: IsarType.stringList,
    ),
    r'listIdMessageSent': PropertySchema(
      id: 7,
      name: r'listIdMessageSent',
      type: IsarType.stringList,
    ),
    r'roomId': PropertySchema(
      id: 8,
      name: r'roomId',
      type: IsarType.string,
    ),
    r'roomType': PropertySchema(
      id: 9,
      name: r'roomType',
      type: IsarType.string,
    ),
    r'tipeUserLawan': PropertySchema(
      id: 10,
      name: r'tipeUserLawan',
      type: IsarType.string,
    ),
    r'unread': PropertySchema(
      id: 11,
      name: r'unread',
      type: IsarType.long,
    ),
    r'userIds': PropertySchema(
      id: 12,
      name: r'userIds',
      type: IsarType.stringList,
    ),
    r'usernameLawan': PropertySchema(
      id: 13,
      name: r'usernameLawan',
      type: IsarType.string,
    )
  },
  estimateSize: _roomChatEntityEstimateSize,
  serialize: _roomChatEntitySerialize,
  deserialize: _roomChatEntityDeserialize,
  deserializeProp: _roomChatEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'roomId': IndexSchema(
      id: -3609232324653216207,
      name: r'roomId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'roomId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _roomChatEntityGetId,
  getLinks: _roomChatEntityGetLinks,
  attach: _roomChatEntityAttach,
  version: '3.1.0+1',
);

int _roomChatEntityEstimateSize(
  RoomChatEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.idLawan.length * 3;
  {
    final value = object.idMediaLawan;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.lastMessage.length * 3;
  bytesCount += 3 + object.listIdMessageReceived.length * 3;
  {
    for (var i = 0; i < object.listIdMessageReceived.length; i++) {
      final value = object.listIdMessageReceived[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.listIdMessageSent.length * 3;
  {
    for (var i = 0; i < object.listIdMessageSent.length; i++) {
      final value = object.listIdMessageSent[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.roomId.length * 3;
  bytesCount += 3 + object.roomType.length * 3;
  {
    final value = object.tipeUserLawan;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userIds.length * 3;
  {
    for (var i = 0; i < object.userIds.length; i++) {
      final value = object.userIds[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.usernameLawan;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _roomChatEntitySerialize(
  RoomChatEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.countStatusReceived);
  writer.writeLong(offsets[1], object.countStatusSent);
  writer.writeString(offsets[2], object.idLawan);
  writer.writeString(offsets[3], object.idMediaLawan);
  writer.writeString(offsets[4], object.lastMessage);
  writer.writeDateTime(offsets[5], object.lastMessageAt);
  writer.writeStringList(offsets[6], object.listIdMessageReceived);
  writer.writeStringList(offsets[7], object.listIdMessageSent);
  writer.writeString(offsets[8], object.roomId);
  writer.writeString(offsets[9], object.roomType);
  writer.writeString(offsets[10], object.tipeUserLawan);
  writer.writeLong(offsets[11], object.unread);
  writer.writeStringList(offsets[12], object.userIds);
  writer.writeString(offsets[13], object.usernameLawan);
}

RoomChatEntity _roomChatEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RoomChatEntity();
  object.countStatusReceived = reader.readLong(offsets[0]);
  object.countStatusSent = reader.readLong(offsets[1]);
  object.id = id;
  object.idLawan = reader.readString(offsets[2]);
  object.idMediaLawan = reader.readStringOrNull(offsets[3]);
  object.lastMessage = reader.readString(offsets[4]);
  object.lastMessageAt = reader.readDateTime(offsets[5]);
  object.listIdMessageReceived = reader.readStringList(offsets[6]) ?? [];
  object.listIdMessageSent = reader.readStringList(offsets[7]) ?? [];
  object.roomId = reader.readString(offsets[8]);
  object.roomType = reader.readString(offsets[9]);
  object.tipeUserLawan = reader.readStringOrNull(offsets[10]);
  object.unread = reader.readLong(offsets[11]);
  object.userIds = reader.readStringList(offsets[12]) ?? [];
  object.usernameLawan = reader.readStringOrNull(offsets[13]);
  return object;
}

P _roomChatEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readStringList(offset) ?? []) as P;
    case 7:
      return (reader.readStringList(offset) ?? []) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readStringList(offset) ?? []) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _roomChatEntityGetId(RoomChatEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _roomChatEntityGetLinks(RoomChatEntity object) {
  return [];
}

void _roomChatEntityAttach(
    IsarCollection<dynamic> col, Id id, RoomChatEntity object) {
  object.id = id;
}

extension RoomChatEntityByIndex on IsarCollection<RoomChatEntity> {
  Future<RoomChatEntity?> getByRoomId(String roomId) {
    return getByIndex(r'roomId', [roomId]);
  }

  RoomChatEntity? getByRoomIdSync(String roomId) {
    return getByIndexSync(r'roomId', [roomId]);
  }

  Future<bool> deleteByRoomId(String roomId) {
    return deleteByIndex(r'roomId', [roomId]);
  }

  bool deleteByRoomIdSync(String roomId) {
    return deleteByIndexSync(r'roomId', [roomId]);
  }

  Future<List<RoomChatEntity?>> getAllByRoomId(List<String> roomIdValues) {
    final values = roomIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'roomId', values);
  }

  List<RoomChatEntity?> getAllByRoomIdSync(List<String> roomIdValues) {
    final values = roomIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'roomId', values);
  }

  Future<int> deleteAllByRoomId(List<String> roomIdValues) {
    final values = roomIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'roomId', values);
  }

  int deleteAllByRoomIdSync(List<String> roomIdValues) {
    final values = roomIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'roomId', values);
  }

  Future<Id> putByRoomId(RoomChatEntity object) {
    return putByIndex(r'roomId', object);
  }

  Id putByRoomIdSync(RoomChatEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'roomId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRoomId(List<RoomChatEntity> objects) {
    return putAllByIndex(r'roomId', objects);
  }

  List<Id> putAllByRoomIdSync(List<RoomChatEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'roomId', objects, saveLinks: saveLinks);
  }
}

extension RoomChatEntityQueryWhereSort
    on QueryBuilder<RoomChatEntity, RoomChatEntity, QWhere> {
  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RoomChatEntityQueryWhere
    on QueryBuilder<RoomChatEntity, RoomChatEntity, QWhereClause> {
  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterWhereClause> roomIdEqualTo(
      String roomId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'roomId',
        value: [roomId],
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterWhereClause>
      roomIdNotEqualTo(String roomId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'roomId',
              lower: [],
              upper: [roomId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'roomId',
              lower: [roomId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'roomId',
              lower: [roomId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'roomId',
              lower: [],
              upper: [roomId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RoomChatEntityQueryFilter
    on QueryBuilder<RoomChatEntity, RoomChatEntity, QFilterCondition> {
  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      countStatusReceivedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'countStatusReceived',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      countStatusReceivedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'countStatusReceived',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      countStatusReceivedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'countStatusReceived',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      countStatusReceivedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'countStatusReceived',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      countStatusSentEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'countStatusSent',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      countStatusSentGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'countStatusSent',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      countStatusSentLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'countStatusSent',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      countStatusSentBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'countStatusSent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idLawanEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idLawanGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idLawanLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idLawanBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idLawan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idLawanStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idLawanEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idLawanContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idLawanMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idLawan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idLawanIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idLawan',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idLawanIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idLawan',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'idMediaLawan',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'idMediaLawan',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idMediaLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idMediaLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idMediaLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idMediaLawan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idMediaLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idMediaLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idMediaLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idMediaLawan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idMediaLawan',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      idMediaLawanIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idMediaLawan',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastMessage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      lastMessageAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listIdMessageReceived',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'listIdMessageReceived',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'listIdMessageReceived',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'listIdMessageReceived',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'listIdMessageReceived',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'listIdMessageReceived',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'listIdMessageReceived',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'listIdMessageReceived',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listIdMessageReceived',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'listIdMessageReceived',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageReceived',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageReceived',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageReceived',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageReceived',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageReceived',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageReceivedLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageReceived',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listIdMessageSent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'listIdMessageSent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'listIdMessageSent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'listIdMessageSent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'listIdMessageSent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'listIdMessageSent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'listIdMessageSent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'listIdMessageSent',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listIdMessageSent',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'listIdMessageSent',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageSent',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageSent',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageSent',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageSent',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageSent',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      listIdMessageSentLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'listIdMessageSent',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'roomId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'roomId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'roomId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'roomId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'roomId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'roomId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'roomId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'roomId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'roomId',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'roomId',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'roomType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'roomType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'roomType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'roomType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'roomType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'roomType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'roomType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'roomType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'roomType',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      roomTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'roomType',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tipeUserLawan',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tipeUserLawan',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipeUserLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tipeUserLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tipeUserLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tipeUserLawan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tipeUserLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tipeUserLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tipeUserLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tipeUserLawan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipeUserLawan',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      tipeUserLawanIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tipeUserLawan',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      unreadEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unread',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      unreadGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unread',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      unreadLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unread',
        value: value,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      unreadBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unread',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userIds',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userIds',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'userIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'userIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'userIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'userIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'userIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      userIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'userIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'usernameLawan',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'usernameLawan',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usernameLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usernameLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usernameLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usernameLawan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'usernameLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'usernameLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'usernameLawan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'usernameLawan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usernameLawan',
        value: '',
      ));
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterFilterCondition>
      usernameLawanIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'usernameLawan',
        value: '',
      ));
    });
  }
}

extension RoomChatEntityQueryObject
    on QueryBuilder<RoomChatEntity, RoomChatEntity, QFilterCondition> {}

extension RoomChatEntityQueryLinks
    on QueryBuilder<RoomChatEntity, RoomChatEntity, QFilterCondition> {}

extension RoomChatEntityQuerySortBy
    on QueryBuilder<RoomChatEntity, RoomChatEntity, QSortBy> {
  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByCountStatusReceived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countStatusReceived', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByCountStatusReceivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countStatusReceived', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByCountStatusSent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countStatusSent', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByCountStatusSentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countStatusSent', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy> sortByIdLawan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idLawan', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByIdLawanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idLawan', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByIdMediaLawan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idMediaLawan', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByIdMediaLawanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idMediaLawan', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByLastMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessage', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByLastMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessage', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByLastMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByLastMessageAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy> sortByRoomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomId', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByRoomIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomId', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy> sortByRoomType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomType', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByRoomTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomType', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByTipeUserLawan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipeUserLawan', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByTipeUserLawanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipeUserLawan', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy> sortByUnread() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unread', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByUnreadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unread', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByUsernameLawan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usernameLawan', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      sortByUsernameLawanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usernameLawan', Sort.desc);
    });
  }
}

extension RoomChatEntityQuerySortThenBy
    on QueryBuilder<RoomChatEntity, RoomChatEntity, QSortThenBy> {
  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByCountStatusReceived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countStatusReceived', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByCountStatusReceivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countStatusReceived', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByCountStatusSent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countStatusSent', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByCountStatusSentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'countStatusSent', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy> thenByIdLawan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idLawan', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByIdLawanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idLawan', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByIdMediaLawan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idMediaLawan', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByIdMediaLawanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idMediaLawan', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByLastMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessage', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByLastMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessage', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByLastMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByLastMessageAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy> thenByRoomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomId', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByRoomIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomId', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy> thenByRoomType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomType', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByRoomTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomType', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByTipeUserLawan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipeUserLawan', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByTipeUserLawanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipeUserLawan', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy> thenByUnread() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unread', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByUnreadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unread', Sort.desc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByUsernameLawan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usernameLawan', Sort.asc);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QAfterSortBy>
      thenByUsernameLawanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usernameLawan', Sort.desc);
    });
  }
}

extension RoomChatEntityQueryWhereDistinct
    on QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct> {
  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct>
      distinctByCountStatusReceived() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'countStatusReceived');
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct>
      distinctByCountStatusSent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'countStatusSent');
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct> distinctByIdLawan(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'idLawan', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct>
      distinctByIdMediaLawan({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'idMediaLawan', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct> distinctByLastMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct>
      distinctByLastMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageAt');
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct>
      distinctByListIdMessageReceived() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'listIdMessageReceived');
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct>
      distinctByListIdMessageSent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'listIdMessageSent');
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct> distinctByRoomId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'roomId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct> distinctByRoomType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'roomType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct>
      distinctByTipeUserLawan({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tipeUserLawan',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct> distinctByUnread() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unread');
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct> distinctByUserIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userIds');
    });
  }

  QueryBuilder<RoomChatEntity, RoomChatEntity, QDistinct>
      distinctByUsernameLawan({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usernameLawan',
          caseSensitive: caseSensitive);
    });
  }
}

extension RoomChatEntityQueryProperty
    on QueryBuilder<RoomChatEntity, RoomChatEntity, QQueryProperty> {
  QueryBuilder<RoomChatEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RoomChatEntity, int, QQueryOperations>
      countStatusReceivedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'countStatusReceived');
    });
  }

  QueryBuilder<RoomChatEntity, int, QQueryOperations>
      countStatusSentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'countStatusSent');
    });
  }

  QueryBuilder<RoomChatEntity, String, QQueryOperations> idLawanProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idLawan');
    });
  }

  QueryBuilder<RoomChatEntity, String?, QQueryOperations>
      idMediaLawanProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idMediaLawan');
    });
  }

  QueryBuilder<RoomChatEntity, String, QQueryOperations> lastMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessage');
    });
  }

  QueryBuilder<RoomChatEntity, DateTime, QQueryOperations>
      lastMessageAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageAt');
    });
  }

  QueryBuilder<RoomChatEntity, List<String>, QQueryOperations>
      listIdMessageReceivedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'listIdMessageReceived');
    });
  }

  QueryBuilder<RoomChatEntity, List<String>, QQueryOperations>
      listIdMessageSentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'listIdMessageSent');
    });
  }

  QueryBuilder<RoomChatEntity, String, QQueryOperations> roomIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'roomId');
    });
  }

  QueryBuilder<RoomChatEntity, String, QQueryOperations> roomTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'roomType');
    });
  }

  QueryBuilder<RoomChatEntity, String?, QQueryOperations>
      tipeUserLawanProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tipeUserLawan');
    });
  }

  QueryBuilder<RoomChatEntity, int, QQueryOperations> unreadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unread');
    });
  }

  QueryBuilder<RoomChatEntity, List<String>, QQueryOperations>
      userIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userIds');
    });
  }

  QueryBuilder<RoomChatEntity, String?, QQueryOperations>
      usernameLawanProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usernameLawan');
    });
  }
}
