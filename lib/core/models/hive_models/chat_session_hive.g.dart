// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatSessionHiveAdapter extends TypeAdapter<ChatSessionHive> {
  @override
  final int typeId = 2;

  @override
  ChatSessionHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatSessionHive(
      sessionId: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      model: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChatSessionHive obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.model)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSessionHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
