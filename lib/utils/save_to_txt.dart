import 'dart:io';
import 'package:BiroPOS/providers/narociloitem_provider.dart';
import 'package:BiroPOS/providers/selecteditem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

int stevecRacunov = 0;

Future<bool> saveFileNextToExe(String txtContent, BuildContext context,
    WidgetRef ref, bool isBesteronSucess) async {
  final exePath = Platform.resolvedExecutable;
  final exeDir = path.dirname(exePath);
  try {
    String timeStamp = generateTimeStamp();

    stevecRacunov++;
    String stevilkaRacuna = stevecRacunov.toString();

    final filePath =
        path.join(exeDir, 'BiroPOS_natisni_${timeStamp}_$stevilkaRacuna.txt');

    final file = File(filePath);
    await file.writeAsString(txtContent);
    return true;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Napaka pri windows tiskanju: $e")));
    return false;
  }
}

String generateTimeStamp() {
  DateTime currentDate = DateTime.now();

  String formattedDate = DateFormat('yyMMdd').format(currentDate);
  String formattedTime = DateFormat('HHmmssSSS').format(currentDate);

  return '${formattedDate}_$formattedTime';
}

List<String> ocistiVrstice(List<String> vrstice) {
  return vrstice.map((vrstica) {
    vrstica = vrstica.trim(); // odstrani \r, presledke ipd.
    if (vrstica.startsWith(',')) {
      return vrstica.substring(1).trimLeft(); // odstrani vejico in presledek
    }
    return vrstica;
  }).toList();
}
