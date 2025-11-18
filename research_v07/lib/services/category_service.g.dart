// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomCategoryAdapter extends TypeAdapter<CustomCategory> {
  @override
  final int typeId = 10;

  @override
  CustomCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      iconCodePoint: fields[3] as int,
      colorValue: fields[4] as int,
      gradientColors: (fields[5] as List).cast<int>(),
      createdAt: fields[6] as DateTime,
      createdBy: fields[7] as String,
      isActive: fields[8] as bool,
      usageCount: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CustomCategory obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconCodePoint)
      ..writeByte(4)
      ..write(obj.colorValue)
      ..writeByte(5)
      ..write(obj.gradientColors)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.createdBy)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.usageCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
