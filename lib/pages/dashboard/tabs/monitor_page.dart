import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tambal/widgets/custom_recent_patient.dart';
import 'package:tambal/services/realtime_database_service.dart';
import 'package:tambal/models/dispensing_log.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DispensingLog> _allLogs = [];
  List<DispensingLog> _filteredLogs = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterLogs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLogs() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredLogs = _allLogs;
      });
    } else {
      setState(() {
        _filteredLogs = _allLogs.where((log) {
          return log.patientName.toLowerCase().contains(query) ||
              log.day.toLowerCase().contains(query) ||
              log.time.toLowerCase().contains(query) ||
              log.medicineList!.any((medicine) =>
                  medicine.toString().toLowerCase().contains(query));
        }).toList();
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    final status = await Permission.manageExternalStorage.request();

    if (!mounted) return false;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to save files.'),
            ),
          );
        }
      });
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  Future<String> _getDownloadPath(String fileName) async {
    if (Platform.isAndroid) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }
      return '${downloadsDir.path}/$fileName';
    }

    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('Unable to access external storage directory.');
    }
    return '${directory.path}/$fileName';
  }

  Future<void> _saveAsExcel() async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return;

    if (_filteredLogs.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    final excel = Excel.createExcel();
    const sheetName = 'Dispensing Logs';
    final sheet = excel[sheetName];

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow([
      TextCellValue('Patient Name'),
      TextCellValue('Day'),
      TextCellValue('Time'),
      TextCellValue('Medicines'),
    ]);

    for (var log in _filteredLogs) {
      sheet.appendRow([
        TextCellValue(log.patientName),
        TextCellValue(log.day),
        TextCellValue(log.time),
        TextCellValue(log.medicineList?.join(', ') ?? ''),
      ]);
    }

    final path = await _getDownloadPath('DispensingLogs.xlsx');
    final file = File(path);

    await file.writeAsBytes(excel.save()!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel file saved to downloads')),
      );
    }
  }

  Future<void> _saveAsPDF() async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return;

    if (_filteredLogs.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(
                color: PdfColors.grey700,
                fontSize: 12,
              ),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Dispensing Logs',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateTime.now().toString().split(' ')[0],
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue700,
              ),
              headerHeight: 25,
              cellHeight: 40,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 12,
              ),
              headers: ['Patient Name', 'Day', 'Time', 'Medicines'],
              data: _filteredLogs
                  .map((log) => [
                        log.patientName,
                        log.day,
                        log.time,
                        log.medicineList?.join(', ') ?? '',
                      ])
                  .toList(),
            ),
          ];
        },
      ),
    );

    try {
      final path = await _getDownloadPath('DispensingLogs.pdf');
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF file saved to downloads')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recently Dispensed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A86FF),
                  ),
                ),
                IconButton(
                  onPressed: _showDownloadOptions,
                  icon: const Icon(Icons.save_alt),
                  color: const Color(0xFFA9A9A9),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<DispensingLog>>(
                stream: RealtimeDatabaseService().streamDispensingLogs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No dispensing logs available.'));
                  }
                  _allLogs = snapshot.data!;
                  _filteredLogs =
                      _filteredLogs.isEmpty ? _allLogs : _filteredLogs;
                  return ListView.builder(
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      return RecentPatientCard(
                        patientName: log.patientName,
                        day: log.day,
                        time: log.time,
                        medicineList: log.medicineList
                                ?.map((item) => item.toString())
                                .toList() ??
                            [],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDownloadOptions() async {
    await showDialog(
      context: context,
      builder: (localContext) {
        return AlertDialog(
          title: const Text('Download As'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(localContext);
                  await _saveAsExcel();
                },
                icon: const Icon(Icons.file_copy),
                label: const Text('Excel'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(localContext);
                  await _saveAsPDF();
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
              ),
            ],
          ),
        );
      },
    );
  }
}
