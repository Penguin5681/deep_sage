// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_imports_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecentImportsModelAdapter extends TypeAdapter<RecentImportsModel> {
  @override
  final int typeId = 1;

  @override
  RecentImportsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecentImportsModel(
      fileName: fields[0] as String,
      fileType: fields[1] as String,
      fileSize: fields[3] as String,
      importTime: fields[2] as DateTime,
      filePath: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecentImportsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.fileName)
      ..writeByte(1)
      ..write(obj.fileType)
      ..writeByte(2)
      ..write(obj.importTime)
      ..writeByte(3)
      ..write(obj.fileSize)
      ..writeByte(4)
      ..write(obj.filePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentImportsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
