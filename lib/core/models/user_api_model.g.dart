// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_api_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserApiAdapter extends TypeAdapter<UserApi> {
  @override
  final int typeId = 0;

  @override
  UserApi read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserApi(
      kaggleApiKey: fields[1] as String,
      kaggleUserName: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserApi obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.kaggleUserName)
      ..writeByte(1)
      ..write(obj.kaggleApiKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserApiAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
