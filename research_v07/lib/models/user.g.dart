// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      username: fields[1] as String,
      email: fields[2] as String,
      displayName: fields[3] as String,
      role: fields[4] as UserRole,
      bio: fields[5] as String?,
      profileImagePath: fields[6] as String?,
      department: fields[7] as String?,
      institution: fields[8] as String?,
      interests: (fields[9] as List).cast<String>(),
      following: (fields[10] as List).cast<String>(),
      followers: (fields[11] as List).cast<String>(),
      paperCount: fields[12] as int,
      citationCount: fields[13] as int,
      createdAt: fields[14] as DateTime,
      lastLoginAt: fields[15] as DateTime,
      isActive: fields[16] as bool,
      isVerified: fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.displayName)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.bio)
      ..writeByte(6)
      ..write(obj.profileImagePath)
      ..writeByte(7)
      ..write(obj.department)
      ..writeByte(8)
      ..write(obj.institution)
      ..writeByte(9)
      ..write(obj.interests)
      ..writeByte(10)
      ..write(obj.following)
      ..writeByte(11)
      ..write(obj.followers)
      ..writeByte(12)
      ..write(obj.paperCount)
      ..writeByte(13)
      ..write(obj.citationCount)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.lastLoginAt)
      ..writeByte(16)
      ..write(obj.isActive)
      ..writeByte(17)
      ..write(obj.isVerified);
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

class UserSessionAdapter extends TypeAdapter<UserSession> {
  @override
  final int typeId = 2;

  @override
  UserSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSession(
      userId: fields[0] as String,
      token: fields[1] as String,
      loginTime: fields[2] as DateTime,
      expiryTime: fields[3] as DateTime,
      rememberMe: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserSession obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.token)
      ..writeByte(2)
      ..write(obj.loginTime)
      ..writeByte(3)
      ..write(obj.expiryTime)
      ..writeByte(4)
      ..write(obj.rememberMe);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 3;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      userId: fields[0] as String,
      enableNotifications: fields[1] as bool,
      enableEmailNotifications: fields[2] as bool,
      themeMode: fields[3] as String,
      language: fields[4] as String,
      blockedUsers: (fields[5] as List).cast<String>(),
      showProfile: fields[6] as bool,
      allowFollows: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.enableNotifications)
      ..writeByte(2)
      ..write(obj.enableEmailNotifications)
      ..writeByte(3)
      ..write(obj.themeMode)
      ..writeByte(4)
      ..write(obj.language)
      ..writeByte(5)
      ..write(obj.blockedUsers)
      ..writeByte(6)
      ..write(obj.showProfile)
      ..writeByte(7)
      ..write(obj.allowFollows);
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
  final int typeId = 1;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.student;
      case 1:
        return UserRole.professor;
      case 2:
        return UserRole.researcher;
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
      case UserRole.professor:
        writer.writeByte(1);
        break;
      case UserRole.researcher:
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
