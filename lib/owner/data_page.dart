import 'package:flutter/material.dart';
import 'data/ui/data_header.dart';
import 'data/ui/export_data_card.dart';
import 'data/ui/import_data_card.dart';
import 'data/ui/clear_data_section.dart';
import 'data/ui/pro_tip_section.dart';
import 'data/logic/data_operations_helper.dart';

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DataHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExportDataCard(
                    onPressed: () => DataOperationsHelper.exportData(context),
                  ),
                  const SizedBox(height: 16),
                  ImportDataCard(
                    onPressed: () => DataOperationsHelper.importData(context),
                  ),
                  const SizedBox(height: 16),
                  ClearDataSection(
                    onPressed: () => DataOperationsHelper.clearAllData(context),
                  ),
                  const SizedBox(height: 16),
                  const ProTipSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}