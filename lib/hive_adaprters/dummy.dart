import 'package:hive/hive.dart';

class DeletedAdapterPlaceholder {}

class DeletedAdapterPlaceholderAdapter
    extends TypeAdapter<DeletedAdapterPlaceholder> {
  @override
  final int typeId = 33;

  @override
  DeletedAdapterPlaceholder read(BinaryReader reader) {
    // prezri podatke
    return DeletedAdapterPlaceholder();
  }

  @override
  void write(BinaryWriter writer, DeletedAdapterPlaceholder obj) {
    // ne piši ničesar
  }
}
