import 'package:intl/intl.dart';

String generateCode() {
  DateTime currentDate = DateTime.now();

  String formattedDate = DateFormat('ddMM').format(currentDate);

  int? code = int.tryParse(formattedDate);

  code ??= 0;

  code = code * 13;

  String codeString = code.toString().substring(0, 4);

  String finalCodeString = "$codeString#";

  return finalCodeString;
}

List<String> insertCodeInReceipt(List<String> lines) {
  final codeline = generateCode();
  final updatedLines = <String>[];

  for (var line in lines) {
    if (line.contains("Programska oprema BiroPOS")) {
      updatedLines.add(codeline);
    }
    updatedLines.add(line);
  }
  return updatedLines;
}
