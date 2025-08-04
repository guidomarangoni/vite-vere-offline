import 'package:flutter/material.dart';
import '../localization/lingua_supportata.dart';

class LanguageDropdown extends StatelessWidget {
  final List<LinguaSupportata> lingue;
  final String? linguaSelezionata;
  final ValueChanged<String?> onChanged;

  const LanguageDropdown({
    required this.lingue,
    required this.linguaSelezionata,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: linguaSelezionata,
      hint: const Text('Seleziona lingua'),
      items: lingue.map((lingua) {
        return DropdownMenuItem<String>(
          value: lingua.nome,
          child: Text('${lingua.nome} (${lingua.livello})'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
} 