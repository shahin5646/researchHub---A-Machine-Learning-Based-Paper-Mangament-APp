// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 10;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      profileImageUrl: fields[3] as String?,
      role: fields[4] as UserRole,
      department: fields[5] as String?,
      affiliation: fields[6] as String?,
      researchInterests: (fields[7] as List).cast<String>(),
      bookmarkedPapers: (fields[8] as List).cast<String>(),
      downloadedPapers: (fields[9] as List).cast<String>(),
      paperRatings: (fields[10] as Map).cast<String, double>(),
      searchHistory: (fields[11] as List).cast<String>(),
      preferences: fields[12] as UserPreferences,
      createdAt: fields[13] as DateTime,
      lastLoginAt: fields[14] as DateTime,
      isActive: fields[15] as bool,
      password: fields[16] as String?,
      following: (fields[17] as List).cast<String>(),
      followers: (fields[18] as List).cast<String>(),
      bio: fields[19] as String?,
      website: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.profileImageUrl)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.department)
      ..writeByte(6)
      ..write(obj.affiliation)
      ..writeByte(7)
      ..write(obj.researchInterests)
      ..writeByte(8)
      ..write(obj.bookmarkedPapers)
      ..writeByte(9)
      ..write(obj.downloadedPapers)
      ..writeByte(10)
      ..write(obj.paperRatings)
      ..writeByte(11)
      ..write(obj.searchHistory)
      ..writeByte(12)
      ..write(obj.preferences)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.lastLoginAt)
      ..writeByte(15)
      ..write(obj.isActive)
      ..writeByte(16)
      ..write(obj.password)
      ..writeByte(17)
      ..write(obj.following)
      ..writeByte(18)
      ..write(obj.followers)
      ..writeByte(19)
      ..write(obj.bio)
      ..writeByte(20)
      ..write(obj.website);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 12;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      theme: fields[0] as String,
      language: fields[1] as String,
      emailNotifications: fields[2] as bool,
      pushNotifications: fields[3] as bool,
      preferredCategories: (fields[4] as List).cast<String>(),
      resultsPerPage: fields[5] as int,
      citationFormat: fields[6] as String,
      autoDownload: fields[7] as bool,
      customSettings: (fields[8] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.theme)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.emailNotifications)
      ..writeByte(3)
      ..write(obj.pushNotifications)
      ..writeByte(4)
      ..write(obj.preferredCategories)
      ..writeByte(5)
      ..write(obj.resultsPerPage)
      ..writeByte(6)
      ..write(obj.citationFormat)
      ..writeByte(7)
      ..write(obj.autoDownload)
      ..writeByte(8)
      ..write(obj.customSettings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 11;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.student;
      case 1:
        return UserRole.researcher;
      case 2:
        return UserRole.faculty;
      case 3:
        return UserRole.admin;
      case 4:
        return UserRole.guest;
      default:
        return UserRole.student;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.student:
        writer.writeByte(0);
        break;
      case UserRole.researcher:
        writer.writeByte(1);
        break;
      case UserRole.faculty:
        writer.writeByte(2);
        break;
      case UserRole.admin:
        writer.writeByte(3);
        break;
      case UserRole.guest:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
