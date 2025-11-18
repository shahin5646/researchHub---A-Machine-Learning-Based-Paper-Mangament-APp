// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paper_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaperCategoryAdapter extends TypeAdapter<PaperCategory> {
  @override
  final int typeId = 1;

  @override
  PaperCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaperCategory(
      name: fields[0] as String,
      description: fields[1] as String,
      papers: (fields[2] as List).cast<String>(),
      icon: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PaperCategory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.papers)
      ..writeByte(3)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
