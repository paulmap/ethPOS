// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_action.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AiActionAdapter extends TypeAdapter<AiAction> {
  @override
  final int typeId = 25;

  @override
  AiAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiAction(
      id: fields[0] as String,
      kind: fields[1] as AiActionKind,
      summary: fields[2] as String,
      detail: fields[3] as String,
      at: fields[4] as DateTime,
      undoPayload: fields[5] as String?,
      undone: fields[6] as bool,
      supervisorOnly: fields[7] as bool,
      approvedBy: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AiAction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kind)
      ..writeByte(2)
      ..write(obj.summary)
      ..writeByte(3)
      ..write(obj.detail)
      ..writeByte(4)
      ..write(obj.at)
      ..writeByte(5)
      ..write(obj.undoPayload)
      ..writeByte(6)
      ..write(obj.undone)
      ..writeByte(7)
      ..write(obj.supervisorOnly)
      ..writeByte(8)
      ..write(obj.approvedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AiActionKindAdapter extends TypeAdapter<AiActionKind> {
  @override
  final int typeId = 24;

  @override
  AiActionKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AiActionKind.setReorderPoint;
      case 1:
        return AiActionKind.moveStock;
      case 2:
        return AiActionKind.proposeDiscount;
      case 3:
        return AiActionKind.flagPattern;
      default:
        return AiActionKind.setReorderPoint;
    }
  }

  @override
  void write(BinaryWriter writer, AiActionKind obj) {
    switch (obj) {
      case AiActionKind.setReorderPoint:
        writer.writeByte(0);
        break;
      case AiActionKind.moveStock:
        writer.writeByte(1);
        break;
      case AiActionKind.proposeDiscount:
        writer.writeByte(2);
        break;
      case AiActionKind.flagPattern:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiActionKindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
