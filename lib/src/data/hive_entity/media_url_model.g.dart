// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_url_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaUrlModelAdapter extends TypeAdapter<MediaUrlModel> {
  @override
  final int typeId = 2;

  @override
  MediaUrlModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaUrlModel(
      url: fields[0] as String?,
      expiredAt: fields[1] as DateTime?,
      isCompressed: fields[2] as bool?,
      contentType: fields[3] as String?,
      thumbUrl: fields[4] as String?,
      size: fields[5] as int?,
      idMedia: fields[6] as String?,
      noIdMedia: fields[7] as String?,
      localPath: fields[8] as String?,
      localThumbPath: fields[9] as String?,
      cachedAt: fields[10] as DateTime?,
      lastAccessedAt: fields[11] as DateTime?,
      cacheStatus: fields[12] as MediaCacheStatus,
    );
  }

  @override
  void write(BinaryWriter writer, MediaUrlModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.expiredAt)
      ..writeByte(2)
      ..write(obj.isCompressed)
      ..writeByte(3)
      ..write(obj.contentType)
      ..writeByte(4)
      ..write(obj.thumbUrl)
      ..writeByte(5)
      ..write(obj.size)
      ..writeByte(6)
      ..write(obj.idMedia)
      ..writeByte(7)
      ..write(obj.noIdMedia)
      ..writeByte(8)
      ..write(obj.localPath)
      ..writeByte(9)
      ..write(obj.localThumbPath)
      ..writeByte(10)
      ..write(obj.cachedAt)
      ..writeByte(11)
      ..write(obj.lastAccessedAt)
      ..writeByte(12)
      ..write(obj.cacheStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaUrlModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MediaCacheStatusAdapter extends TypeAdapter<MediaCacheStatus> {
  @override
  final int typeId = 1;

  @override
  MediaCacheStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MediaCacheStatus.notCached;
      case 1:
        return MediaCacheStatus.cached;
      case 2:
        return MediaCacheStatus.failed;
      case 3:
        return MediaCacheStatus.expired;
      default:
        return MediaCacheStatus.notCached;
    }
  }

  @override
  void write(BinaryWriter writer, MediaCacheStatus obj) {
    switch (obj) {
      case MediaCacheStatus.notCached:
        writer.writeByte(0);
        break;
      case MediaCacheStatus.cached:
        writer.writeByte(1);
        break;
      case MediaCacheStatus.failed:
        writer.writeByte(2);
        break;
      case MediaCacheStatus.expired:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaCacheStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
