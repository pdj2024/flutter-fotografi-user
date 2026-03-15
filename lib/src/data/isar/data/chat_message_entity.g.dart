// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetChatMessageEntityCollection on Isar {
  IsarCollection<ChatMessageEntity> get chatMessageEntitys => this.collection();
}

const ChatMessageEntitySchema = CollectionSchema(
  name: r'ChatMessageEntity',
  id: 8398983736130033389,
  properties: {
    r'idPaket': PropertySchema(
      id: 0,
      name: r'idPaket',
      type: IsarType.string,
    ),
    r'jenisPesan': PropertySchema(
      id: 1,
      name: r'jenisPesan',
      type: IsarType.string,
    ),
    r'localId': PropertySchema(
      id: 2,
      name: r'localId',
      type: IsarType.string,
    ),
    r'message': PropertySchema(
      id: 3,
      name: r'message',
      type: IsarType.string,
    ),
    r'messageId': PropertySchema(
      id: 4,
      name: r'messageId',
      type: IsarType.string,
    ),
    r'noInvoice': PropertySchema(
      id: 5,
      name: r'noInvoice',
      type: IsarType.string,
    ),
    r'noPenawaran': PropertySchema(
      id: 6,
      name: r'noPenawaran',
      type: IsarType.string,
    ),
    r'paket': PropertySchema(
      id: 7,
      name: r'paket',
      type: IsarType.object,
      target: r'EmbeddedPaket',
    ),
    r'penawaran': PropertySchema(
      id: 8,
      name: r'penawaran',
      type: IsarType.object,
      target: r'EmbeddedPenawaran',
    ),
    r'pesanan': PropertySchema(
      id: 9,
      name: r'pesanan',
      type: IsarType.object,
      target: r'EmbeddedPesanan',
    ),
    r'readAt': PropertySchema(
      id: 10,
      name: r'readAt',
      type: IsarType.dateTime,
    ),
    r'receivedAt': PropertySchema(
      id: 11,
      name: r'receivedAt',
      type: IsarType.dateTime,
    ),
    r'receiverIds': PropertySchema(
      id: 12,
      name: r'receiverIds',
      type: IsarType.stringList,
    ),
    r'roomId': PropertySchema(
      id: 13,
      name: r'roomId',
      type: IsarType.string,
    ),
    r'sendStatus': PropertySchema(
      id: 14,
      name: r'sendStatus',
      type: IsarType.string,
    ),
    r'senderId': PropertySchema(
      id: 15,
      name: r'senderId',
      type: IsarType.string,
    ),
    r'sentAt': PropertySchema(
      id: 16,
      name: r'sentAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _chatMessageEntityEstimateSize,
  serialize: _chatMessageEntitySerialize,
  deserialize: _chatMessageEntityDeserialize,
  deserializeProp: _chatMessageEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'messageId': IndexSchema(
      id: -635287409172016016,
      name: r'messageId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'messageId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'roomId': IndexSchema(
      id: -3609232324653216207,
      name: r'roomId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'roomId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'sendStatus': IndexSchema(
      id: 8625173981760716777,
      name: r'sendStatus',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sendStatus',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'EmbeddedPaket': EmbeddedPaketSchema,
    r'EmbeddedPenawaran': EmbeddedPenawaranSchema,
    r'EmbeddedPesanan': EmbeddedPesananSchema
  },
  getId: _chatMessageEntityGetId,
  getLinks: _chatMessageEntityGetLinks,
  attach: _chatMessageEntityAttach,
  version: '3.1.0+1',
);

int _chatMessageEntityEstimateSize(
  ChatMessageEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.idPaket;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.jenisPesan;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.localId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.message.length * 3;
  bytesCount += 3 + object.messageId.length * 3;
  {
    final value = object.noInvoice;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.noPenawaran;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paket;
    if (value != null) {
      bytesCount += 3 +
          EmbeddedPaketSchema.estimateSize(
              value, allOffsets[EmbeddedPaket]!, allOffsets);
    }
  }
  {
    final value = object.penawaran;
    if (value != null) {
      bytesCount += 3 +
          EmbeddedPenawaranSchema.estimateSize(
              value, allOffsets[EmbeddedPenawaran]!, allOffsets);
    }
  }
  {
    final value = object.pesanan;
    if (value != null) {
      bytesCount += 3 +
          EmbeddedPesananSchema.estimateSize(
              value, allOffsets[EmbeddedPesanan]!, allOffsets);
    }
  }
  bytesCount += 3 + object.receiverIds.length * 3;
  {
    for (var i = 0; i < object.receiverIds.length; i++) {
      final value = object.receiverIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.roomId.length * 3;
  bytesCount += 3 + object.sendStatus.length * 3;
  bytesCount += 3 + object.senderId.length * 3;
  return bytesCount;
}

void _chatMessageEntitySerialize(
  ChatMessageEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.idPaket);
  writer.writeString(offsets[1], object.jenisPesan);
  writer.writeString(offsets[2], object.localId);
  writer.writeString(offsets[3], object.message);
  writer.writeString(offsets[4], object.messageId);
  writer.writeString(offsets[5], object.noInvoice);
  writer.writeString(offsets[6], object.noPenawaran);
  writer.writeObject<EmbeddedPaket>(
    offsets[7],
    allOffsets,
    EmbeddedPaketSchema.serialize,
    object.paket,
  );
  writer.writeObject<EmbeddedPenawaran>(
    offsets[8],
    allOffsets,
    EmbeddedPenawaranSchema.serialize,
    object.penawaran,
  );
  writer.writeObject<EmbeddedPesanan>(
    offsets[9],
    allOffsets,
    EmbeddedPesananSchema.serialize,
    object.pesanan,
  );
  writer.writeDateTime(offsets[10], object.readAt);
  writer.writeDateTime(offsets[11], object.receivedAt);
  writer.writeStringList(offsets[12], object.receiverIds);
  writer.writeString(offsets[13], object.roomId);
  writer.writeString(offsets[14], object.sendStatus);
  writer.writeString(offsets[15], object.senderId);
  writer.writeDateTime(offsets[16], object.sentAt);
}

ChatMessageEntity _chatMessageEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ChatMessageEntity();
  object.id = id;
  object.idPaket = reader.readStringOrNull(offsets[0]);
  object.jenisPesan = reader.readStringOrNull(offsets[1]);
  object.localId = reader.readStringOrNull(offsets[2]);
  object.message = reader.readString(offsets[3]);
  object.messageId = reader.readString(offsets[4]);
  object.noInvoice = reader.readStringOrNull(offsets[5]);
  object.noPenawaran = reader.readStringOrNull(offsets[6]);
  object.paket = reader.readObjectOrNull<EmbeddedPaket>(
    offsets[7],
    EmbeddedPaketSchema.deserialize,
    allOffsets,
  );
  object.penawaran = reader.readObjectOrNull<EmbeddedPenawaran>(
    offsets[8],
    EmbeddedPenawaranSchema.deserialize,
    allOffsets,
  );
  object.pesanan = reader.readObjectOrNull<EmbeddedPesanan>(
    offsets[9],
    EmbeddedPesananSchema.deserialize,
    allOffsets,
  );
  object.readAt = reader.readDateTimeOrNull(offsets[10]);
  object.receivedAt = reader.readDateTimeOrNull(offsets[11]);
  object.receiverIds = reader.readStringList(offsets[12]) ?? [];
  object.roomId = reader.readString(offsets[13]);
  object.sendStatus = reader.readString(offsets[14]);
  object.senderId = reader.readString(offsets[15]);
  object.sentAt = reader.readDateTime(offsets[16]);
  return object;
}

P _chatMessageEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readObjectOrNull<EmbeddedPaket>(
        offset,
        EmbeddedPaketSchema.deserialize,
        allOffsets,
      )) as P;
    case 8:
      return (reader.readObjectOrNull<EmbeddedPenawaran>(
        offset,
        EmbeddedPenawaranSchema.deserialize,
        allOffsets,
      )) as P;
    case 9:
      return (reader.readObjectOrNull<EmbeddedPesanan>(
        offset,
        EmbeddedPesananSchema.deserialize,
        allOffsets,
      )) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readStringList(offset) ?? []) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _chatMessageEntityGetId(ChatMessageEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _chatMessageEntityGetLinks(
    ChatMessageEntity object) {
  return [];
}

void _chatMessageEntityAttach(
    IsarCollection<dynamic> col, Id id, ChatMessageEntity object) {
  object.id = id;
}

extension ChatMessageEntityByIndex on IsarCollection<ChatMessageEntity> {
  Future<ChatMessageEntity?> getByMessageId(String messageId) {
    return getByIndex(r'messageId', [messageId]);
  }

  ChatMessageEntity? getByMessageIdSync(String messageId) {
    return getByIndexSync(r'messageId', [messageId]);
  }

  Future<bool> deleteByMessageId(String messageId) {
    return deleteByIndex(r'messageId', [messageId]);
  }

  bool deleteByMessageIdSync(String messageId) {
    return deleteByIndexSync(r'messageId', [messageId]);
  }

  Future<List<ChatMessageEntity?>> getAllByMessageId(
      List<String> messageIdValues) {
    final values = messageIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'messageId', values);
  }

  List<ChatMessageEntity?> getAllByMessageIdSync(List<String> messageIdValues) {
    final values = messageIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'messageId', values);
  }

  Future<int> deleteAllByMessageId(List<String> messageIdValues) {
    final values = messageIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'messageId', values);
  }

  int deleteAllByMessageIdSync(List<String> messageIdValues) {
    final values = messageIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'messageId', values);
  }

  Future<Id> putByMessageId(ChatMessageEntity object) {
    return putByIndex(r'messageId', object);
  }

  Id putByMessageIdSync(ChatMessageEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'messageId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMessageId(List<ChatMessageEntity> objects) {
    return putAllByIndex(r'messageId', objects);
  }

  List<Id> putAllByMessageIdSync(List<ChatMessageEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'messageId', objects, saveLinks: saveLinks);
  }
}

extension ChatMessageEntityQueryWhereSort
    on QueryBuilder<ChatMessageEntity, ChatMessageEntity, QWhere> {
  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ChatMessageEntityQueryWhere
    on QueryBuilder<ChatMessageEntity, ChatMessageEntity, QWhereClause> {
  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhereClause>
      messageIdEqualTo(String messageId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'messageId',
        value: [messageId],
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhereClause>
      messageIdNotEqualTo(String messageId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'messageId',
              lower: [],
              upper: [messageId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'messageId',
              lower: [messageId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'messageId',
              lower: [messageId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'messageId',
              lower: [],
              upper: [messageId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhereClause>
      roomIdEqualTo(String roomId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'roomId',
        value: [roomId],
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhereClause>
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhereClause>
      sendStatusEqualTo(String sendStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sendStatus',
        value: [sendStatus],
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterWhereClause>
      sendStatusNotEqualTo(String sendStatus) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sendStatus',
              lower: [],
              upper: [sendStatus],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sendStatus',
              lower: [sendStatus],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sendStatus',
              lower: [sendStatus],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sendStatus',
              lower: [],
              upper: [sendStatus],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ChatMessageEntityQueryFilter
    on QueryBuilder<ChatMessageEntity, ChatMessageEntity, QFilterCondition> {
  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'idPaket',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'idPaket',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idPaket',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idPaket',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      idPaketIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'jenisPesan',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'jenisPesan',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jenisPesan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jenisPesan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jenisPesan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jenisPesan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jenisPesan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jenisPesan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jenisPesan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jenisPesan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jenisPesan',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      jenisPesanIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jenisPesan',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localId',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localId',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      localIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'message',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'message',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messageId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'messageId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'messageId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageId',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      messageIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'messageId',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'noInvoice',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'noInvoice',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noInvoice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noInvoice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noInvoice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noInvoice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noInvoice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noInvoice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noInvoice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noInvoice',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noInvoice',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noInvoiceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noInvoice',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'noPenawaran',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'noPenawaran',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noPenawaran',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noPenawaran',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noPenawaran',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      noPenawaranIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noPenawaran',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      paketIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paket',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      paketIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paket',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      penawaranIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'penawaran',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      penawaranIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'penawaran',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      pesananIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pesanan',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      pesananIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pesanan',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      readAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'readAt',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      readAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'readAt',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      readAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      readAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'readAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      readAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'readAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      readAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'readAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receivedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'receivedAt',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receivedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'receivedAt',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receivedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receivedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receivedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receivedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receivedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receivedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receivedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receivedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiverIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiverIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiverIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiverIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'receiverIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'receiverIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'receiverIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'receiverIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiverIds',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'receiverIds',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'receiverIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'receiverIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'receiverIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'receiverIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'receiverIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      receiverIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'receiverIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
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

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      roomIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'roomId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      roomIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'roomId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      roomIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'roomId',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      roomIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'roomId',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sendStatusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sendStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sendStatusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sendStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sendStatusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sendStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sendStatusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sendStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sendStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sendStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sendStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sendStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sendStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sendStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sendStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sendStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sendStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sendStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sendStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sendStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      senderIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      senderIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      senderIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      senderIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'senderId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      senderIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      senderIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      senderIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'senderId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      senderIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'senderId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      senderIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderId',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      senderIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'senderId',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sentAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sentAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sentAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      sentAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sentAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ChatMessageEntityQueryObject
    on QueryBuilder<ChatMessageEntity, ChatMessageEntity, QFilterCondition> {
  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      paket(FilterQuery<EmbeddedPaket> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'paket');
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      penawaran(FilterQuery<EmbeddedPenawaran> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'penawaran');
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterFilterCondition>
      pesanan(FilterQuery<EmbeddedPesanan> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'pesanan');
    });
  }
}

extension ChatMessageEntityQueryLinks
    on QueryBuilder<ChatMessageEntity, ChatMessageEntity, QFilterCondition> {}

extension ChatMessageEntityQuerySortBy
    on QueryBuilder<ChatMessageEntity, ChatMessageEntity, QSortBy> {
  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByIdPaket() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idPaket', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByIdPaketDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idPaket', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByJenisPesan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jenisPesan', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByJenisPesanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jenisPesan', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByNoInvoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noInvoice', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByNoInvoiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noInvoice', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByNoPenawaran() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noPenawaran', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByNoPenawaranDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noPenawaran', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readAt', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByReadAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readAt', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByReceivedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByReceivedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByRoomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomId', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortByRoomIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomId', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortBySendStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sendStatus', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortBySendStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sendStatus', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortBySenderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortBySenderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      sortBySentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.desc);
    });
  }
}

extension ChatMessageEntityQuerySortThenBy
    on QueryBuilder<ChatMessageEntity, ChatMessageEntity, QSortThenBy> {
  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByIdPaket() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idPaket', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByIdPaketDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idPaket', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByJenisPesan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jenisPesan', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByJenisPesanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jenisPesan', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByMessageId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByMessageIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageId', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByNoInvoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noInvoice', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByNoInvoiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noInvoice', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByNoPenawaran() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noPenawaran', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByNoPenawaranDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noPenawaran', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readAt', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByReadAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readAt', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByReceivedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByReceivedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByRoomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomId', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenByRoomIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roomId', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenBySendStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sendStatus', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenBySendStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sendStatus', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenBySenderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenBySenderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderId', Sort.desc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.asc);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QAfterSortBy>
      thenBySentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.desc);
    });
  }
}

extension ChatMessageEntityQueryWhereDistinct
    on QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct> {
  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctByIdPaket({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'idPaket', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctByJenisPesan({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jenisPesan', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctByLocalId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctByMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctByMessageId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctByNoInvoice({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noInvoice', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctByNoPenawaran({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noPenawaran', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctByReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readAt');
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctByReceivedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receivedAt');
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctByReceiverIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiverIds');
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctByRoomId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'roomId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctBySendStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sendStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctBySenderId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'senderId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ChatMessageEntity, ChatMessageEntity, QDistinct>
      distinctBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sentAt');
    });
  }
}

extension ChatMessageEntityQueryProperty
    on QueryBuilder<ChatMessageEntity, ChatMessageEntity, QQueryProperty> {
  QueryBuilder<ChatMessageEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ChatMessageEntity, String?, QQueryOperations> idPaketProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idPaket');
    });
  }

  QueryBuilder<ChatMessageEntity, String?, QQueryOperations>
      jenisPesanProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jenisPesan');
    });
  }

  QueryBuilder<ChatMessageEntity, String?, QQueryOperations> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localId');
    });
  }

  QueryBuilder<ChatMessageEntity, String, QQueryOperations> messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<ChatMessageEntity, String, QQueryOperations>
      messageIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageId');
    });
  }

  QueryBuilder<ChatMessageEntity, String?, QQueryOperations>
      noInvoiceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noInvoice');
    });
  }

  QueryBuilder<ChatMessageEntity, String?, QQueryOperations>
      noPenawaranProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noPenawaran');
    });
  }

  QueryBuilder<ChatMessageEntity, EmbeddedPaket?, QQueryOperations>
      paketProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paket');
    });
  }

  QueryBuilder<ChatMessageEntity, EmbeddedPenawaran?, QQueryOperations>
      penawaranProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'penawaran');
    });
  }

  QueryBuilder<ChatMessageEntity, EmbeddedPesanan?, QQueryOperations>
      pesananProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pesanan');
    });
  }

  QueryBuilder<ChatMessageEntity, DateTime?, QQueryOperations>
      readAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readAt');
    });
  }

  QueryBuilder<ChatMessageEntity, DateTime?, QQueryOperations>
      receivedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receivedAt');
    });
  }

  QueryBuilder<ChatMessageEntity, List<String>, QQueryOperations>
      receiverIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiverIds');
    });
  }

  QueryBuilder<ChatMessageEntity, String, QQueryOperations> roomIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'roomId');
    });
  }

  QueryBuilder<ChatMessageEntity, String, QQueryOperations>
      sendStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sendStatus');
    });
  }

  QueryBuilder<ChatMessageEntity, String, QQueryOperations> senderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'senderId');
    });
  }

  QueryBuilder<ChatMessageEntity, DateTime, QQueryOperations> sentAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sentAt');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const EmbeddedPaketSchema = Schema(
  name: r'EmbeddedPaket',
  id: -832336214912979540,
  properties: {
    r'harga': PropertySchema(
      id: 0,
      name: r'harga',
      type: IsarType.long,
    ),
    r'idVendor': PropertySchema(
      id: 1,
      name: r'idVendor',
      type: IsarType.string,
    ),
    r'namaPaket': PropertySchema(
      id: 2,
      name: r'namaPaket',
      type: IsarType.string,
    ),
    r'noId': PropertySchema(
      id: 3,
      name: r'noId',
      type: IsarType.string,
    ),
    r'rincian': PropertySchema(
      id: 4,
      name: r'rincian',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 5,
      name: r'status',
      type: IsarType.string,
    )
  },
  estimateSize: _embeddedPaketEstimateSize,
  serialize: _embeddedPaketSerialize,
  deserialize: _embeddedPaketDeserialize,
  deserializeProp: _embeddedPaketDeserializeProp,
);

int _embeddedPaketEstimateSize(
  EmbeddedPaket object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.idVendor.length * 3;
  bytesCount += 3 + object.namaPaket.length * 3;
  bytesCount += 3 + object.noId.length * 3;
  bytesCount += 3 + object.rincian.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _embeddedPaketSerialize(
  EmbeddedPaket object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.harga);
  writer.writeString(offsets[1], object.idVendor);
  writer.writeString(offsets[2], object.namaPaket);
  writer.writeString(offsets[3], object.noId);
  writer.writeString(offsets[4], object.rincian);
  writer.writeString(offsets[5], object.status);
}

EmbeddedPaket _embeddedPaketDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EmbeddedPaket();
  object.harga = reader.readLong(offsets[0]);
  object.idVendor = reader.readString(offsets[1]);
  object.namaPaket = reader.readString(offsets[2]);
  object.noId = reader.readString(offsets[3]);
  object.rincian = reader.readString(offsets[4]);
  object.status = reader.readString(offsets[5]);
  return object;
}

P _embeddedPaketDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension EmbeddedPaketQueryFilter
    on QueryBuilder<EmbeddedPaket, EmbeddedPaket, QFilterCondition> {
  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      hargaEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'harga',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      hargaGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'harga',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      hargaLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'harga',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      hargaBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'harga',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      idVendorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      idVendorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      idVendorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      idVendorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idVendor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      idVendorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      idVendorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      idVendorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      idVendorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idVendor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      idVendorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      idVendorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      namaPaketEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      namaPaketGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      namaPaketLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      namaPaketBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namaPaket',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      namaPaketStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      namaPaketEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      namaPaketContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      namaPaketMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namaPaket',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      namaPaketIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      namaPaketIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namaPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition> noIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      noIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      noIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition> noIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      noIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      noIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      noIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition> noIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      noIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noId',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      noIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noId',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      rincianEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rincian',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      rincianGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rincian',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      rincianLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rincian',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      rincianBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rincian',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      rincianStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rincian',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      rincianEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rincian',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      rincianContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rincian',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      rincianMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rincian',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      rincianIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rincian',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      rincianIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rincian',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPaket, EmbeddedPaket, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }
}

extension EmbeddedPaketQueryObject
    on QueryBuilder<EmbeddedPaket, EmbeddedPaket, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const EmbeddedPenawaranSchema = Schema(
  name: r'EmbeddedPenawaran',
  id: -7969133469589360546,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deskripsi': PropertySchema(
      id: 1,
      name: r'deskripsi',
      type: IsarType.string,
    ),
    r'harga': PropertySchema(
      id: 2,
      name: r'harga',
      type: IsarType.long,
    ),
    r'idCustomer': PropertySchema(
      id: 3,
      name: r'idCustomer',
      type: IsarType.string,
    ),
    r'idPaket': PropertySchema(
      id: 4,
      name: r'idPaket',
      type: IsarType.string,
    ),
    r'idVendor': PropertySchema(
      id: 5,
      name: r'idVendor',
      type: IsarType.string,
    ),
    r'kota': PropertySchema(
      id: 6,
      name: r'kota',
      type: IsarType.string,
    ),
    r'lokasi': PropertySchema(
      id: 7,
      name: r'lokasi',
      type: IsarType.string,
    ),
    r'namaCustomer': PropertySchema(
      id: 8,
      name: r'namaCustomer',
      type: IsarType.string,
    ),
    r'namaKota': PropertySchema(
      id: 9,
      name: r'namaKota',
      type: IsarType.string,
    ),
    r'namaPaket': PropertySchema(
      id: 10,
      name: r'namaPaket',
      type: IsarType.string,
    ),
    r'namaVendor': PropertySchema(
      id: 11,
      name: r'namaVendor',
      type: IsarType.string,
    ),
    r'noId': PropertySchema(
      id: 12,
      name: r'noId',
      type: IsarType.string,
    ),
    r'noPesanan': PropertySchema(
      id: 13,
      name: r'noPesanan',
      type: IsarType.string,
    ),
    r'noTrackingPenawaran': PropertySchema(
      id: 14,
      name: r'noTrackingPenawaran',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 15,
      name: r'status',
      type: IsarType.string,
    ),
    r'tglRealisasi': PropertySchema(
      id: 16,
      name: r'tglRealisasi',
      type: IsarType.dateTime,
    ),
    r'updatedAt': PropertySchema(
      id: 17,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _embeddedPenawaranEstimateSize,
  serialize: _embeddedPenawaranSerialize,
  deserialize: _embeddedPenawaranDeserialize,
  deserializeProp: _embeddedPenawaranDeserializeProp,
);

int _embeddedPenawaranEstimateSize(
  EmbeddedPenawaran object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.deskripsi.length * 3;
  bytesCount += 3 + object.idCustomer.length * 3;
  bytesCount += 3 + object.idPaket.length * 3;
  bytesCount += 3 + object.idVendor.length * 3;
  bytesCount += 3 + object.kota.length * 3;
  bytesCount += 3 + object.lokasi.length * 3;
  bytesCount += 3 + object.namaCustomer.length * 3;
  bytesCount += 3 + object.namaKota.length * 3;
  bytesCount += 3 + object.namaPaket.length * 3;
  bytesCount += 3 + object.namaVendor.length * 3;
  bytesCount += 3 + object.noId.length * 3;
  bytesCount += 3 + object.noPesanan.length * 3;
  bytesCount += 3 + object.noTrackingPenawaran.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _embeddedPenawaranSerialize(
  EmbeddedPenawaran object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.deskripsi);
  writer.writeLong(offsets[2], object.harga);
  writer.writeString(offsets[3], object.idCustomer);
  writer.writeString(offsets[4], object.idPaket);
  writer.writeString(offsets[5], object.idVendor);
  writer.writeString(offsets[6], object.kota);
  writer.writeString(offsets[7], object.lokasi);
  writer.writeString(offsets[8], object.namaCustomer);
  writer.writeString(offsets[9], object.namaKota);
  writer.writeString(offsets[10], object.namaPaket);
  writer.writeString(offsets[11], object.namaVendor);
  writer.writeString(offsets[12], object.noId);
  writer.writeString(offsets[13], object.noPesanan);
  writer.writeString(offsets[14], object.noTrackingPenawaran);
  writer.writeString(offsets[15], object.status);
  writer.writeDateTime(offsets[16], object.tglRealisasi);
  writer.writeDateTime(offsets[17], object.updatedAt);
}

EmbeddedPenawaran _embeddedPenawaranDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EmbeddedPenawaran();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.deskripsi = reader.readString(offsets[1]);
  object.harga = reader.readLong(offsets[2]);
  object.idCustomer = reader.readString(offsets[3]);
  object.idPaket = reader.readString(offsets[4]);
  object.idVendor = reader.readString(offsets[5]);
  object.kota = reader.readString(offsets[6]);
  object.lokasi = reader.readString(offsets[7]);
  object.namaCustomer = reader.readString(offsets[8]);
  object.namaKota = reader.readString(offsets[9]);
  object.namaPaket = reader.readString(offsets[10]);
  object.namaVendor = reader.readString(offsets[11]);
  object.noId = reader.readString(offsets[12]);
  object.noPesanan = reader.readString(offsets[13]);
  object.noTrackingPenawaran = reader.readString(offsets[14]);
  object.status = reader.readString(offsets[15]);
  object.tglRealisasi = reader.readDateTime(offsets[16]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[17]);
  return object;
}

P _embeddedPenawaranDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readDateTime(offset)) as P;
    case 17:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension EmbeddedPenawaranQueryFilter
    on QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QFilterCondition> {
  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
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

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
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

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
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

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      deskripsiEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deskripsi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      deskripsiGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deskripsi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      deskripsiLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deskripsi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      deskripsiBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deskripsi',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      deskripsiStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deskripsi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      deskripsiEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deskripsi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      deskripsiContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deskripsi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      deskripsiMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deskripsi',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      deskripsiIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deskripsi',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      deskripsiIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deskripsi',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      hargaEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'harga',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      hargaGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'harga',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      hargaLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'harga',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      hargaBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'harga',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idCustomerEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idCustomerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idCustomerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idCustomerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idCustomer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idCustomerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idCustomerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idCustomerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idCustomerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idCustomer',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idCustomerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idCustomer',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idCustomerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idCustomer',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idPaketEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idPaketGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idPaketLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idPaketBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idPaket',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idPaketStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idPaketEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idPaketContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idPaketMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idPaket',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idPaketIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idPaketIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idVendorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idVendorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idVendorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idVendorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idVendor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idVendorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idVendorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idVendorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idVendorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idVendor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idVendorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      idVendorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      kotaEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      kotaGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      kotaLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      kotaBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kota',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      kotaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      kotaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      kotaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      kotaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kota',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      kotaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kota',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      kotaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kota',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      lokasiEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      lokasiGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      lokasiLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      lokasiBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lokasi',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      lokasiStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      lokasiEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      lokasiContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      lokasiMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lokasi',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      lokasiIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lokasi',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      lokasiIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lokasi',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaCustomerEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaCustomerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaCustomerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaCustomerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namaCustomer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaCustomerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaCustomerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaCustomerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaCustomerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namaCustomer',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaCustomerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaCustomer',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaCustomerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namaCustomer',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaKotaEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaKotaGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaKotaLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaKotaBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namaKota',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaKotaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaKotaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaKotaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaKotaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namaKota',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaKotaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaKota',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaKotaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namaKota',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaPaketEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaPaketGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaPaketLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaPaketBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namaPaket',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaPaketStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaPaketEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaPaketContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaPaketMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namaPaket',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaPaketIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaPaketIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namaPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaVendorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaVendorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaVendorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaVendorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namaVendor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaVendorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaVendorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaVendorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaVendorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namaVendor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaVendorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      namaVendorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namaVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noId',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noId',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noPesananEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noPesananGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noPesananLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noPesananBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noPesanan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noPesananStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noPesananEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noPesananContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noPesananMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noPesanan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noPesananIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noPesanan',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noPesananIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noPesanan',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noTrackingPenawaranEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noTrackingPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noTrackingPenawaranGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noTrackingPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noTrackingPenawaranLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noTrackingPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noTrackingPenawaranBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noTrackingPenawaran',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noTrackingPenawaranStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noTrackingPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noTrackingPenawaranEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noTrackingPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noTrackingPenawaranContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noTrackingPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noTrackingPenawaranMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noTrackingPenawaran',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noTrackingPenawaranIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noTrackingPenawaran',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      noTrackingPenawaranIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noTrackingPenawaran',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      tglRealisasiEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tglRealisasi',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      tglRealisasiGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tglRealisasi',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      tglRealisasiLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tglRealisasi',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      tglRealisasiBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tglRealisasi',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
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

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
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

  QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
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
}

extension EmbeddedPenawaranQueryObject
    on QueryBuilder<EmbeddedPenawaran, EmbeddedPenawaran, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const EmbeddedPesananSchema = Schema(
  name: r'EmbeddedPesanan',
  id: 3975123546476478011,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deskripsiProgresPesanan': PropertySchema(
      id: 1,
      name: r'deskripsiProgresPesanan',
      type: IsarType.string,
    ),
    r'expiryTime': PropertySchema(
      id: 2,
      name: r'expiryTime',
      type: IsarType.dateTime,
    ),
    r'grandTotal': PropertySchema(
      id: 3,
      name: r'grandTotal',
      type: IsarType.long,
    ),
    r'harga': PropertySchema(
      id: 4,
      name: r'harga',
      type: IsarType.long,
    ),
    r'idCustomer': PropertySchema(
      id: 5,
      name: r'idCustomer',
      type: IsarType.string,
    ),
    r'idMediaVendor': PropertySchema(
      id: 6,
      name: r'idMediaVendor',
      type: IsarType.string,
    ),
    r'idPaket': PropertySchema(
      id: 7,
      name: r'idPaket',
      type: IsarType.string,
    ),
    r'idPaymentGateway': PropertySchema(
      id: 8,
      name: r'idPaymentGateway',
      type: IsarType.string,
    ),
    r'idVendor': PropertySchema(
      id: 9,
      name: r'idVendor',
      type: IsarType.string,
    ),
    r'inclPpn': PropertySchema(
      id: 10,
      name: r'inclPpn',
      type: IsarType.bool,
    ),
    r'kota': PropertySchema(
      id: 11,
      name: r'kota',
      type: IsarType.string,
    ),
    r'linkSnap': PropertySchema(
      id: 12,
      name: r'linkSnap',
      type: IsarType.string,
    ),
    r'linkUrl': PropertySchema(
      id: 13,
      name: r'linkUrl',
      type: IsarType.string,
    ),
    r'lokasi': PropertySchema(
      id: 14,
      name: r'lokasi',
      type: IsarType.string,
    ),
    r'metodeBayar': PropertySchema(
      id: 15,
      name: r'metodeBayar',
      type: IsarType.string,
    ),
    r'namaCustomer': PropertySchema(
      id: 16,
      name: r'namaCustomer',
      type: IsarType.string,
    ),
    r'namaKota': PropertySchema(
      id: 17,
      name: r'namaKota',
      type: IsarType.string,
    ),
    r'namaPaket': PropertySchema(
      id: 18,
      name: r'namaPaket',
      type: IsarType.string,
    ),
    r'namaVendor': PropertySchema(
      id: 19,
      name: r'namaVendor',
      type: IsarType.string,
    ),
    r'noBukti': PropertySchema(
      id: 20,
      name: r'noBukti',
      type: IsarType.string,
    ),
    r'noPenawaran': PropertySchema(
      id: 21,
      name: r'noPenawaran',
      type: IsarType.string,
    ),
    r'noTrackingPesanan': PropertySchema(
      id: 22,
      name: r'noTrackingPesanan',
      type: IsarType.string,
    ),
    r'orderIdMidtrans': PropertySchema(
      id: 23,
      name: r'orderIdMidtrans',
      type: IsarType.string,
    ),
    r'paymentNumber1': PropertySchema(
      id: 24,
      name: r'paymentNumber1',
      type: IsarType.string,
    ),
    r'paymentNumber2': PropertySchema(
      id: 25,
      name: r'paymentNumber2',
      type: IsarType.string,
    ),
    r'ppn': PropertySchema(
      id: 26,
      name: r'ppn',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 27,
      name: r'status',
      type: IsarType.string,
    ),
    r'statusBayar': PropertySchema(
      id: 28,
      name: r'statusBayar',
      type: IsarType.string,
    ),
    r'statusProgresPesanan': PropertySchema(
      id: 29,
      name: r'statusProgresPesanan',
      type: IsarType.string,
    ),
    r'subtotal': PropertySchema(
      id: 30,
      name: r'subtotal',
      type: IsarType.long,
    ),
    r'tglRealisasi': PropertySchema(
      id: 31,
      name: r'tglRealisasi',
      type: IsarType.dateTime,
    ),
    r'totDpp': PropertySchema(
      id: 32,
      name: r'totDpp',
      type: IsarType.double,
    ),
    r'totPpn': PropertySchema(
      id: 33,
      name: r'totPpn',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 34,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _embeddedPesananEstimateSize,
  serialize: _embeddedPesananSerialize,
  deserialize: _embeddedPesananDeserialize,
  deserializeProp: _embeddedPesananDeserializeProp,
);

int _embeddedPesananEstimateSize(
  EmbeddedPesanan object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.deskripsiProgresPesanan;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.idCustomer.length * 3;
  {
    final value = object.idMediaVendor;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.idPaket.length * 3;
  {
    final value = object.idPaymentGateway;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.idVendor.length * 3;
  bytesCount += 3 + object.kota.length * 3;
  {
    final value = object.linkSnap;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.linkUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.lokasi.length * 3;
  {
    final value = object.metodeBayar;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.namaCustomer;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.namaKota;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.namaPaket.length * 3;
  {
    final value = object.namaVendor;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.noBukti.length * 3;
  {
    final value = object.noPenawaran;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.noTrackingPesanan;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.orderIdMidtrans;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paymentNumber1;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paymentNumber2;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.status;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.statusBayar;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.statusProgresPesanan;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _embeddedPesananSerialize(
  EmbeddedPesanan object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.deskripsiProgresPesanan);
  writer.writeDateTime(offsets[2], object.expiryTime);
  writer.writeLong(offsets[3], object.grandTotal);
  writer.writeLong(offsets[4], object.harga);
  writer.writeString(offsets[5], object.idCustomer);
  writer.writeString(offsets[6], object.idMediaVendor);
  writer.writeString(offsets[7], object.idPaket);
  writer.writeString(offsets[8], object.idPaymentGateway);
  writer.writeString(offsets[9], object.idVendor);
  writer.writeBool(offsets[10], object.inclPpn);
  writer.writeString(offsets[11], object.kota);
  writer.writeString(offsets[12], object.linkSnap);
  writer.writeString(offsets[13], object.linkUrl);
  writer.writeString(offsets[14], object.lokasi);
  writer.writeString(offsets[15], object.metodeBayar);
  writer.writeString(offsets[16], object.namaCustomer);
  writer.writeString(offsets[17], object.namaKota);
  writer.writeString(offsets[18], object.namaPaket);
  writer.writeString(offsets[19], object.namaVendor);
  writer.writeString(offsets[20], object.noBukti);
  writer.writeString(offsets[21], object.noPenawaran);
  writer.writeString(offsets[22], object.noTrackingPesanan);
  writer.writeString(offsets[23], object.orderIdMidtrans);
  writer.writeString(offsets[24], object.paymentNumber1);
  writer.writeString(offsets[25], object.paymentNumber2);
  writer.writeLong(offsets[26], object.ppn);
  writer.writeString(offsets[27], object.status);
  writer.writeString(offsets[28], object.statusBayar);
  writer.writeString(offsets[29], object.statusProgresPesanan);
  writer.writeLong(offsets[30], object.subtotal);
  writer.writeDateTime(offsets[31], object.tglRealisasi);
  writer.writeDouble(offsets[32], object.totDpp);
  writer.writeLong(offsets[33], object.totPpn);
  writer.writeDateTime(offsets[34], object.updatedAt);
}

EmbeddedPesanan _embeddedPesananDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EmbeddedPesanan();
  object.createdAt = reader.readDateTimeOrNull(offsets[0]);
  object.deskripsiProgresPesanan = reader.readStringOrNull(offsets[1]);
  object.expiryTime = reader.readDateTimeOrNull(offsets[2]);
  object.grandTotal = reader.readLong(offsets[3]);
  object.harga = reader.readLong(offsets[4]);
  object.idCustomer = reader.readString(offsets[5]);
  object.idMediaVendor = reader.readStringOrNull(offsets[6]);
  object.idPaket = reader.readString(offsets[7]);
  object.idPaymentGateway = reader.readStringOrNull(offsets[8]);
  object.idVendor = reader.readString(offsets[9]);
  object.inclPpn = reader.readBoolOrNull(offsets[10]);
  object.kota = reader.readString(offsets[11]);
  object.linkSnap = reader.readStringOrNull(offsets[12]);
  object.linkUrl = reader.readStringOrNull(offsets[13]);
  object.lokasi = reader.readString(offsets[14]);
  object.metodeBayar = reader.readStringOrNull(offsets[15]);
  object.namaCustomer = reader.readStringOrNull(offsets[16]);
  object.namaKota = reader.readStringOrNull(offsets[17]);
  object.namaPaket = reader.readString(offsets[18]);
  object.namaVendor = reader.readStringOrNull(offsets[19]);
  object.noBukti = reader.readString(offsets[20]);
  object.noPenawaran = reader.readStringOrNull(offsets[21]);
  object.noTrackingPesanan = reader.readStringOrNull(offsets[22]);
  object.orderIdMidtrans = reader.readStringOrNull(offsets[23]);
  object.paymentNumber1 = reader.readStringOrNull(offsets[24]);
  object.paymentNumber2 = reader.readStringOrNull(offsets[25]);
  object.ppn = reader.readLongOrNull(offsets[26]);
  object.status = reader.readStringOrNull(offsets[27]);
  object.statusBayar = reader.readStringOrNull(offsets[28]);
  object.statusProgresPesanan = reader.readStringOrNull(offsets[29]);
  object.subtotal = reader.readLong(offsets[30]);
  object.tglRealisasi = reader.readDateTime(offsets[31]);
  object.totDpp = reader.readDoubleOrNull(offsets[32]);
  object.totPpn = reader.readLongOrNull(offsets[33]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[34]);
  return object;
}

P _embeddedPesananDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readBoolOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readLongOrNull(offset)) as P;
    case 27:
      return (reader.readStringOrNull(offset)) as P;
    case 28:
      return (reader.readStringOrNull(offset)) as P;
    case 29:
      return (reader.readStringOrNull(offset)) as P;
    case 30:
      return (reader.readLong(offset)) as P;
    case 31:
      return (reader.readDateTime(offset)) as P;
    case 32:
      return (reader.readDoubleOrNull(offset)) as P;
    case 33:
      return (reader.readLongOrNull(offset)) as P;
    case 34:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension EmbeddedPesananQueryFilter
    on QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QFilterCondition> {
  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
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

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      createdAtLessThan(
    DateTime? value, {
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

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deskripsiProgresPesanan',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deskripsiProgresPesanan',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deskripsiProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deskripsiProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deskripsiProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deskripsiProgresPesanan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deskripsiProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deskripsiProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deskripsiProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deskripsiProgresPesanan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deskripsiProgresPesanan',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      deskripsiProgresPesananIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deskripsiProgresPesanan',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      expiryTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expiryTime',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      expiryTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expiryTime',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      expiryTimeEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiryTime',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      expiryTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expiryTime',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      expiryTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expiryTime',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      expiryTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expiryTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      grandTotalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'grandTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      grandTotalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'grandTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      grandTotalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'grandTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      grandTotalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'grandTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      hargaEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'harga',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      hargaGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'harga',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      hargaLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'harga',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      hargaBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'harga',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idCustomerEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idCustomerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idCustomerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idCustomerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idCustomer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idCustomerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idCustomerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idCustomerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idCustomerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idCustomer',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idCustomerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idCustomer',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idCustomerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idCustomer',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'idMediaVendor',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'idMediaVendor',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idMediaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idMediaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idMediaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idMediaVendor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idMediaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idMediaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idMediaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idMediaVendor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idMediaVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idMediaVendorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idMediaVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaketEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaketGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaketLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaketBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idPaket',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaketStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaketEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaketContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaketMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idPaket',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaketIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaketIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'idPaymentGateway',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'idPaymentGateway',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idPaymentGateway',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idPaymentGateway',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idPaymentGateway',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idPaymentGateway',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idPaymentGateway',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idPaymentGateway',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idPaymentGateway',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idPaymentGateway',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idPaymentGateway',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idPaymentGatewayIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idPaymentGateway',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idVendorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idVendorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idVendorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idVendorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idVendor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idVendorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idVendorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idVendorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idVendorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idVendor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idVendorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      idVendorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      inclPpnIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'inclPpn',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      inclPpnIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'inclPpn',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      inclPpnEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inclPpn',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      kotaEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      kotaGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      kotaLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      kotaBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kota',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      kotaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      kotaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      kotaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      kotaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kota',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      kotaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kota',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      kotaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kota',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'linkSnap',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'linkSnap',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linkSnap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'linkSnap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'linkSnap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'linkSnap',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'linkSnap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'linkSnap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'linkSnap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'linkSnap',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linkSnap',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkSnapIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'linkSnap',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'linkUrl',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'linkUrl',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'linkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'linkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'linkUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'linkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'linkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'linkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'linkUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linkUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      linkUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'linkUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      lokasiEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      lokasiGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      lokasiLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      lokasiBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lokasi',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      lokasiStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      lokasiEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      lokasiContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lokasi',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      lokasiMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lokasi',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      lokasiIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lokasi',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      lokasiIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lokasi',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'metodeBayar',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'metodeBayar',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metodeBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'metodeBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'metodeBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'metodeBayar',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'metodeBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'metodeBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'metodeBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'metodeBayar',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metodeBayar',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      metodeBayarIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'metodeBayar',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'namaCustomer',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'namaCustomer',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namaCustomer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namaCustomer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namaCustomer',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaCustomer',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaCustomerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namaCustomer',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'namaKota',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'namaKota',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namaKota',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namaKota',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namaKota',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaKota',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaKotaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namaKota',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaPaketEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaPaketGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaPaketLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaPaketBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namaPaket',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaPaketStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaPaketEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaPaketContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namaPaket',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaPaketMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namaPaket',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaPaketIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaPaketIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namaPaket',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'namaVendor',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'namaVendor',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namaVendor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namaVendor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namaVendor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      namaVendorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namaVendor',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noBuktiEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noBukti',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noBuktiGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noBukti',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noBuktiLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noBukti',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noBuktiBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noBukti',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noBuktiStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noBukti',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noBuktiEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noBukti',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noBuktiContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noBukti',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noBuktiMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noBukti',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noBuktiIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noBukti',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noBuktiIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noBukti',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'noPenawaran',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'noPenawaran',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noPenawaran',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noPenawaran',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noPenawaran',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noPenawaran',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noPenawaranIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noPenawaran',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'noTrackingPesanan',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'noTrackingPesanan',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noTrackingPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noTrackingPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noTrackingPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noTrackingPesanan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noTrackingPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noTrackingPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noTrackingPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noTrackingPesanan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noTrackingPesanan',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      noTrackingPesananIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noTrackingPesanan',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orderIdMidtrans',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orderIdMidtrans',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderIdMidtrans',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderIdMidtrans',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderIdMidtrans',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderIdMidtrans',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'orderIdMidtrans',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'orderIdMidtrans',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'orderIdMidtrans',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'orderIdMidtrans',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderIdMidtrans',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      orderIdMidtransIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'orderIdMidtrans',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentNumber1',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentNumber1',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentNumber1',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentNumber1',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentNumber1',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentNumber1',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentNumber1',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentNumber1',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentNumber1',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentNumber1',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentNumber1',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber1IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentNumber1',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentNumber2',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentNumber2',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentNumber2',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentNumber2',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentNumber2',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentNumber2',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentNumber2',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentNumber2',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentNumber2',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentNumber2',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentNumber2',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      paymentNumber2IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentNumber2',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      ppnIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ppn',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      ppnIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ppn',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      ppnEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ppn',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      ppnGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ppn',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      ppnLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ppn',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      ppnBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ppn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'statusBayar',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'statusBayar',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statusBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statusBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statusBayar',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'statusBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'statusBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'statusBayar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'statusBayar',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusBayar',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusBayarIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'statusBayar',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'statusProgresPesanan',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'statusProgresPesanan',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statusProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statusProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statusProgresPesanan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'statusProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'statusProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'statusProgresPesanan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'statusProgresPesanan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusProgresPesanan',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      statusProgresPesananIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'statusProgresPesanan',
        value: '',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      subtotalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtotal',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
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

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
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

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      subtotalBetween(
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

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      tglRealisasiEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tglRealisasi',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      tglRealisasiGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tglRealisasi',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      tglRealisasiLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tglRealisasi',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      tglRealisasiBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tglRealisasi',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totDppIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totDpp',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totDppIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totDpp',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totDppEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totDpp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totDppGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totDpp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totDppLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totDpp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totDppBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totDpp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totPpnIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totPpn',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totPpnIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totPpn',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totPpnEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totPpn',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totPpnGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totPpn',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totPpnLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totPpn',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      totPpnBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totPpn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
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

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime? value, {
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

  QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QAfterFilterCondition>
      updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
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
}

extension EmbeddedPesananQueryObject
    on QueryBuilder<EmbeddedPesanan, EmbeddedPesanan, QFilterCondition> {}
