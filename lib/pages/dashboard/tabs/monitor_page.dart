import 'package:flutter/material.dart';
import 'package:tambal/widgets/custom_recent_patient.dart'; // Import your RecentPatientCard widget
import 'package:tambal/services/realtime_database_service.dart'; // Import your RealtimeDatabaseService
import 'package:tambal/models/dispensing_log.dart'; // Import your DispensingLog model

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row with Save Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recently Dispensed', // Section title
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A86FF), // Same blue color
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Save logic to be added later
                  },
                  icon: const Icon(Icons.save_alt),
                  color: const Color(0xFFA9A9A9),
                ),
              ],
            ),
            const SizedBox(height: 16), // Spacing between title and cards

            // Search Field
            Center(
              child: SizedBox(
                width: 320, // Set a fixed width for the search box
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
            const SizedBox(height: 16), // Spacing between search and list

            // StreamBuilder to display dispensing logs
            Expanded(
              child: StreamBuilder<List<DispensingLog>>(
                stream: RealtimeDatabaseService().streamDispensingLogs(),
                builder: (context, snapshot) {
                  // Handle loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Handle error state
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  // Handle empty data state
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No dispensing logs available.'));
                  }

                  // Save the data and apply the filter
                  _allLogs = snapshot.data!;
                  _filteredLogs = _filteredLogs.isEmpty
                      ? _allLogs
                      : _filteredLogs; // Preserve filtered list

                  // Display filtered list of dispensing logs
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
}
