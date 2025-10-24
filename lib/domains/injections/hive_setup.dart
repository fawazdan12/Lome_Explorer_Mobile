import 'package:event_flow/data/models/hive_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Initialiser Hive avec tous les adaptateurs
/// À appeler dans main.dart AVANT setupServiceLocator()
Future<void> setupHive() async {
  // Initialiser Hive
  await Hive.initFlutter();

  // Enregistrer tous les adaptateurs Hive
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(HiveUtilisateurAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(HiveLieuAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(HiveEvenementAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(HiveLocationAdapter());
  }
}

// ==================== ADAPTERS ====================

class HiveUtilisateurAdapter extends TypeAdapter<HiveUtilisateur> {
  @override
  final int typeId = 0;

  @override
  HiveUtilisateur read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveUtilisateur(
      id: fields[0] as String,
      username: fields[1] as String,
      email: fields[2] as String,
      tel: fields[3] as String?,
      dateCreation: fields[4] as DateTime,
      isActive: fields[5] as bool,
      nombreLieux: fields[6] as int,
      nombreEvenements: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HiveUtilisateur obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.tel)
      ..writeByte(4)
      ..write(obj.dateCreation)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.nombreLieux)
      ..writeByte(7)
      ..write(obj.nombreEvenements);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveUtilisateurAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveLieuAdapter extends TypeAdapter<HiveLieu> {
  @override
  final int typeId = 1;

  @override
  HiveLieu read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveLieu(
      id: fields[0] as String,
      nom: fields[1] as String,
      description: fields[2] as String,
      categorie: fields[3] as String,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      dateCreation: fields[6] as DateTime,
      proprietaireNom: fields[7] as String,
      proprietaireId: fields[8] as String,
      nombreEvenements: fields[9] as int,
      moyenneAvis: fields[10] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveLieu obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nom)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.categorie)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.dateCreation)
      ..writeByte(7)
      ..write(obj.proprietaireNom)
      ..writeByte(8)
      ..write(obj.proprietaireId)
      ..writeByte(9)
      ..write(obj.nombreEvenements)
      ..writeByte(10)
      ..write(obj.moyenneAvis);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveLieuAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveEvenementAdapter extends TypeAdapter<HiveEvenement> {
  @override
  final int typeId = 2;

  @override
  HiveEvenement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveEvenement(
      id: fields[0] as String,
      nom: fields[1] as String,
      description: fields[2] as String,
      dateDebut: fields[3] as DateTime,
      dateFin: fields[4] as DateTime,
      lieuId: fields[5] as String,
      lieuNom: fields[6] as String,
      lieuLatitude: fields[7] as double?,
      lieuLongitude: fields[8] as double?,
      organisateurId: fields[9] as String,
      organisateurNom: fields[10] as String,
      moyenneAvis: fields[11] as double?,
      nombreAvis: fields[12] as int,
      distance: fields[13] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveEvenement obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nom)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dateDebut)
      ..writeByte(4)
      ..write(obj.dateFin)
      ..writeByte(5)
      ..write(obj.lieuId)
      ..writeByte(6)
      ..write(obj.lieuNom)
      ..writeByte(7)
      ..write(obj.lieuLatitude)
      ..writeByte(8)
      ..write(obj.lieuLongitude)
      ..writeByte(9)
      ..write(obj.organisateurId)
      ..writeByte(10)
      ..write(obj.organisateurNom)
      ..writeByte(11)
      ..write(obj.moyenneAvis)
      ..writeByte(12)
      ..write(obj.nombreAvis)
      ..writeByte(13)
      ..write(obj.distance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveEvenementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveLocationAdapter extends TypeAdapter<HiveLocation> {
  @override
  final int typeId = 3;

  @override
  HiveLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveLocation(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      address: fields[2] as String?,
      city: fields[3] as String?,
      quartier: fields[4] as String?,
      source: fields[5] as String,
      cachedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HiveLocation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.city)
      ..writeByte(4)
      ..write(obj.quartier)
      ..writeByte(5)
      ..write(obj.source)
      ..writeByte(6)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}