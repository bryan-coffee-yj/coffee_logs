import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../databases/database_helper.dart';

class ExportService {
  static Future<void> exportLogsToCSV(BuildContext context) async {
    try {
      final beans = await DatabaseHelper.instance.getAllCoffeeBeans();
      final logs = await DatabaseHelper.instance.getAllBrewLogs();

      if (logs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No logs to export yet!')),
          );
        }
        return;
      }

      final beanMap = {for (var bean in beans) bean.id: bean};

      List<List<dynamic>> csvData = [
        [
          'Date',
          'Roaster',
          'Bean',
          'Roast Level',
          'Brew Method',
          'Equipment',
          'Grinder',
          'Grind Size',
          'Dose (g)',
          'Yield (g)',
          'Ratio',
          'Temp (°C)',
          'Time (s)',
          'Acidity (1-5)',
          'Sweetness (1-5)',
          'Body (1-5)',
          'Tasting Notes',
        ],
      ];

      for (var log in logs) {
        final bean = beanMap[log.beanId];
        final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(log.dateOfMaking);

        csvData.add([
          dateStr,
          bean?.roasterName ?? 'Unknown Roaster',
          bean?.beanName ?? 'Unknown Bean',
          bean?.roastLevel ?? 'Unknown',
          log.brewMethod,
          log.equipment,
          log.grinder,
          log.grindSize,
          log.dose,
          log.waterMass,
          '1:${log.brewRatio.toStringAsFixed(1)}',
          log.temperature,
          log.brewTimeSeconds,
          log.acidityScore,
          log.sweetnessScore,
          log.bodyScore,
          log.tastingNotes,
        ]);
      }

      // 4. Use our custom native CSV converter!
      String csvString = _convertToCsvString(csvData);

      // 5. Save to device
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/my_coffee_logs.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      // 6. Share the file
      await Share.shareXFiles([
        XFile(path),
      ], text: 'Here is my exported coffee log backup!');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting data: $e')));
      }
    }
  }

  // --- NATIVE CSV CONVERTER ---
  // This completely replaces the need for the 'csv' package.
  static String _convertToCsvString(List<List<dynamic>> data) {
    return data
        .map((row) {
          return row
              .map((item) {
                String str = item?.toString() ?? '';
                // If the text contains a comma, quote, or newline, we must wrap it in quotes
                // so Excel doesn't break. (e.g., "smooth, floral")
                if (str.contains(',') ||
                    str.contains('"') ||
                    str.contains('\n')) {
                  str = str.replaceAll('"', '""'); // Escape existing quotes
                  return '"$str"';
                }
                return str;
              })
              .join(','); // Join columns with commas
        })
        .join('\n'); // Join rows with newlines
  }
}
