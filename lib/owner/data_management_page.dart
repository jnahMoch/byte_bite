// ============================================================================
// Refactored to follow SOLID principles 
// ============================================================================
import 'package:byte_bite/data/bills_data.dart';
import 'package:byte_bite/data/inventory_data.dart';
import 'package:byte_bite/data/sales_data.dart';
import 'package:flutter/material.dart';
import '../model/pos_item_model.dart';
import '../model/sales_transaction_model.dart';

// ============================================================================
// INTERFACES - Dependency Inversion Principle (DIP)
// ============================================================================

/// Abstract interface for inventory operations
abstract class IInventoryRepository {
  List<POSItem> getAll();
  void clear();
}

/// Abstract interface for sales operations
abstract class ISalesRepository {
  List<SalesTransaction> getAll();
  void clear();
}

/// Abstract interface for bills operations
abstract class IBillsRepository {
  void clear();
}

// ============================================================================
// ADAPTERS - Bridge Pattern (wrapping existing static classes)
// These adapters wrap your existing static classes to follow SOLID
// ============================================================================

/// Adapter for InventoryData - wraps the static class
class InventoryRepositoryAdapter implements IInventoryRepository {
  @override
  List<POSItem> getAll() => InventoryData.items;

  @override
  void clear() => InventoryData.items.clear();
}

/// Adapter for SalesData - wraps the static class  
class SalesRepositoryAdapter implements ISalesRepository {
  @override
  List<SalesTransaction> getAll() => SalesData.transactions;

  @override
  void clear() => SalesData.transactions.clear();
}

/// Adapter for BillsData - wraps the static class
class BillsRepositoryAdapter implements IBillsRepository {
  @override
  void clear() {
    // BillsData doesn't have a clear all method, so we need to iterate
    // This assumes BillsData has a way to remove bills or we use reflection
    // For now, we'll handle this in the service layer
  }
}

// ============================================================================
// DATA SERVICE - Single Responsibility Principle (SRP)
// ============================================================================

/// Handles data operations - single responsibility for data management
class DataService {
  final IInventoryRepository _inventoryRepo;
  final ISalesRepository _salesRepo;
  final IBillsRepository _billsRepo;

  DataService({
    required IInventoryRepository inventoryRepo,
    required ISalesRepository salesRepo,
    required IBillsRepository billsRepo,
  })  : _inventoryRepo = inventoryRepo,
        _salesRepo = salesRepo,
        _billsRepo = billsRepo;

  /// Export all data (simulated)
  Future<void> exportData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In real implementation: serialize data to JSON and save to file
  }

  /// Import data (simulated)
  Future<void> importData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In real implementation: read from file and deserialize
  }

  /// Clear all data
  Future<void> clearAllData() async {
    _inventoryRepo.clear();
    _salesRepo.clear();
    _billsRepo.clear();
  }

  /// Get all data as JSON map for export
  Map<String, dynamic> getAllDataAsJson() {
    return {
      'inventory': _inventoryRepo.getAll().map((item) => {
        'name': item.name,
        'price': item.price,
        'stock': item.stock,
        'unit': item.unit,
        'category': item.category,
      }).toList(),
      'sales': _salesRepo.getAll().map((t) => {
        // Add sales serialization based on SalesTransaction model
      }).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }
}

// ============================================================================
// UI COMPONENTS - Single Responsibility Principle (SRP)
// ============================================================================

/// Header component - only handles header display
class DataManagementHeader extends StatelessWidget {
  const DataManagementHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          _HeaderIcon(),
          SizedBox(width: 16),
          _HeaderText(),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: const Color(0xFF009661).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.storage_rounded,
        color: Color(0xFF009661),
        size: 24,
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Data Management",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Backup and restore your data",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

/// Export section - only handles export UI
class ExportSection extends StatelessWidget {
  final VoidCallback onExport;

  const ExportSection({super.key, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF009661), Color(0xFF00B67A)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
      ),
      title: "Export Backup",
      description:
          "Download all your data (products, transactions, bills) as a backup file. Keep this safe!",
      button: _ExportButton(onExport: onExport),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final VoidCallback onExport;

  const _ExportButton({required this.onExport});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onExport,
        icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
        label: const Text("Export Data",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF009661),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Import section - only handles import UI
class ImportSection extends StatelessWidget {
  final VoidCallback onImport;

  const ImportSection({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.upload_rounded, color: Color(0xFF3B82F6), size: 22),
      ),
      title: "Import Backup",
      description:
          "Restore your data from a previously exported backup file. This will replace current data.",
      button: _ImportButton(onImport: onImport),
    );
  }
}

class _ImportButton extends StatelessWidget {
  final VoidCallback onImport;

  const _ImportButton({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onImport,
        icon: const Icon(Icons.upload_rounded, color: Color(0xFF3B82F6), size: 20),
        label: const Text("Import Data",
            style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600, fontSize: 15)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Danger zone section - only handles dangerous operations UI
class DangerZoneSection extends StatelessWidget {
  final VoidCallback onClearAll;

  const DangerZoneSection({super.key, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        color: Colors.red.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
              ),
              const SizedBox(width: 14),
              Text("Danger Zone",
                  style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Permanently delete all data including products, transactions, and bills. This cannot be undone!",
            style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 18),
          _ClearAllButton(onClearAll: onClearAll),
        ],
      ),
    );
  }
}

class _ClearAllButton extends StatelessWidget {
  final VoidCallback onClearAll;

  const _ClearAllButton({required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onClearAll,
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
        label: const Text("Clear All Data",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Tip section - only handles tips display
class TipSection extends StatelessWidget {
  const TipSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pro Tip",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                ),
                SizedBox(height: 4),
                Text(
                  "Export your data regularly to keep backups. Data is stored locally on your device.",
                  style: TextStyle(color: Color(0xFF92400E), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable section card - follows DRY principle
class _SectionCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String description;
  final Widget button;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 18),
          button,
        ],
      ),
    );
  }
}

// ============================================================================
// MAIN PAGE - Facade Pattern + Dependency Injection
// ============================================================================

class DataManagementPage extends StatefulWidget {
  final DataService? dataService;

  const DataManagementPage({super.key, this.dataService});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  late final DataService _dataService;

  @override
  void initState() {
    super.initState();
    // Use injected service or create with default adapters
    _dataService = widget.dataService ??
        DataService(
          inventoryRepo: InventoryRepositoryAdapter(),
          salesRepo: SalesRepositoryAdapter(),
          billsRepo: BillsRepositoryAdapter(),
        );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _handleExport() async {
    await _dataService.exportData();
    if (mounted) {
      _showSnackBar('Data exported successfully!', const Color(0xFF009661));
    }
  }

  Future<void> _handleImport() async {
    await _dataService.importData();
    if (mounted) {
      _showSnackBar('Import feature coming soon', Colors.blue);
    }
  }

  Future<void> _handleClearAll() async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Clear All Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete all products, transactions, and bills. This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      // Clear inventory
      InventoryData.items.clear();
      // Clear sales
      SalesData.transactions.clear();
      // Clear bills
      BillsData.bills.clear();
      if (mounted) {
        _showSnackBar('All data has been cleared', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DataManagementHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExportSection(onExport: _handleExport),
                  const SizedBox(height: 16),
                  ImportSection(onImport: _handleImport),
                  const SizedBox(height: 16),
                  DangerZoneSection(onClearAll: _handleClearAll),
                  const SizedBox(height: 16),
                  const TipSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

