import 'dart:convert';
import 'package:flutter/services.dart';
import 'lingua_supportata.dart';

Future<List<LinguaSupportata>> loadLingueSupportate() async {
  final jsonString = await rootBundle.loadString('assets/lingue_supportate.json');
  final data = json.decode(jsonString);
  final List list = data['lingue_supportate'];
  return list.map((e) => LinguaSupportata.fromJson(e)).toList();
} 