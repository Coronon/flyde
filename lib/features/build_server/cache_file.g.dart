// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_file.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CacheFileAdapter extends TypeAdapter<CacheFile> {
  @override
  final int typeId = 0;

  @override
  CacheFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheFile(
      fields[0] as String,
      fields[1] as String,
      fields[2] as Uint8List,
    );
  }

  @override
  void write(BinaryWriter writer, CacheFile obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.hash)
      ..writeByte(2)
      ..write(obj.data);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
