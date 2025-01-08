import 'package:flutter/material.dart';
import 'custom_alert_card.dart';

class AlertListWidget extends StatefulWidget {
  const AlertListWidget({super.key});

  @override
  State<AlertListWidget> createState() => _AlertListWidgetState();
}

class _AlertListWidgetState extends State<AlertListWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final alerts = [
    {
      'patientName': 'Mr. James Retubado',
      'patientGender': 'Male',
      'patientAge': 52,
      'missedMedicine': 'Neozep',
      'dateMissed': '2024-11-10',
      'timeMissed': '08:30 AM',
    },
    {
      'patientName': 'Mr. Ronerr Villacarlos',
      'patientGender': 'Male',
      'patientAge': 61,
      'missedMedicine': 'Tiki-Tiki',
      'dateMissed': '2024-11-10',
      'timeMissed': '09:00 AM',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alerts',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: const Color(0xFF3A86FF),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Icon(
                Icons.add_alert_rounded,
                color: Colors.grey,
                size: 30.0,
              ),
            ],
          ),
        ),

        // PageView with increased height to fit content
        SizedBox(
          height: 240, // Increased height to fit card and indicators
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return Padding(
                    padding: const EdgeInsets.only(
                        bottom: 20.0), // Space for indicators
                    child: CustomAlertCard(
                      patientName: alert['patientName'] as String,
                      patientGender: alert['patientGender'] as String,
                      patientAge: alert['patientAge'] as int,
                      missedMedicine: alert['missedMedicine'] as String,
                      dateMissed: alert['dateMissed'] as String,
                      timeMissed: alert['timeMissed'] as String,
                    ),
                  );
                },
              ),
              // Page indicators positioned below the PageView content
              Positioned(
                bottom: 8, // Positioned further down
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    alerts.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? const Color(0xFF3A86FF)
                            : const Color(0xFF3A86FF).withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
