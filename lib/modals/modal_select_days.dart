// File: modals/modal_select_days.dart
import 'package:flutter/material.dart';

class ModalSelectDays extends StatefulWidget {
  final List<bool> selectedDays;
  final bool everyDaySelected;
  final Function(bool, List<bool>) onSelectionDone;

  const ModalSelectDays({
    super.key,
    required this.selectedDays,
    required this.everyDaySelected,
    required this.onSelectionDone,
  });

  @override
  ModalSelectDaysState createState() => ModalSelectDaysState();
}

class ModalSelectDaysState extends State<ModalSelectDays> {
  late List<bool> tempSelectedDaysCheck;
  late bool tempEveryDaySelected;

  @override
  void initState() {
    super.initState();
    tempSelectedDaysCheck = List.from(widget.selectedDays);
    tempEveryDaySelected = widget.everyDaySelected;
  }

  @override
  Widget build(BuildContext context) {
    const List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return AlertDialog(
      title: const Text('Select Days'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text('Everyday'),
            value: tempEveryDaySelected,
            onChanged: (bool? value) {
              setState(() {
                tempEveryDaySelected = value ?? false;
                if (tempEveryDaySelected) {
                  tempSelectedDaysCheck = List.generate(7, (_) => false);
                }
              });
            },
          ),
          ...List.generate(7, (index) {
            return CheckboxListTile(
              title: Text(daysOfWeek[index]),
              value: tempSelectedDaysCheck[index],
              onChanged: tempEveryDaySelected
                  ? null
                  : (bool? value) {
                      setState(() {
                        tempSelectedDaysCheck[index] = value ?? false;
                      });
                    },
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSelectionDone(tempEveryDaySelected, tempSelectedDaysCheck);
            Navigator.of(context).pop();
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
