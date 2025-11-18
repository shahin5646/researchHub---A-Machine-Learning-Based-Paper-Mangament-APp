// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'research_paper.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResearchPaperAdapter extends TypeAdapter<ResearchPaper> {
  @override
  final int typeId = 0;

  @override
  ResearchPaper read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResearchPaper(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      journalName: fields[3] as String,
      year: fields[4] as String,
      pdfUrl: fields[5] as String,
      doi: fields[6] as String,
      keywords: (fields[7] as List).cast<String>(),
      abstract: fields[8] as String,
      citations: fields[9] as int,
      authorImagePath: fields[10] as String?,
      views: fields[11] as int?,
      downloads: fields[12] as int?,
      category: fields[13] as String?,
      publishDate: fields[14] as DateTime?,
      isAsset: fields[15] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, ResearchPaper obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.journalName)
      ..writeByte(4)
      ..write(obj.year)
      ..writeByte(5)
      ..write(obj.pdfUrl)
      ..writeByte(6)
      ..write(obj.doi)
      ..writeByte(7)
      ..write(obj.keywords)
      ..writeByte(8)
      ..write(obj.abstract)
      ..writeByte(9)
      ..write(obj.citations)
      ..writeByte(10)
      ..write(obj.authorImagePath)
      ..writeByte(11)
      ..write(obj.views)
      ..writeByte(12)
      ..write(obj.downloads)
      ..writeByte(13)
      ..write(obj.category)
      ..writeByte(14)
      ..write(obj.publishDate)
      ..writeByte(15)
      ..write(obj.isAsset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResearchPaperAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
