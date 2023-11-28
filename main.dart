import 'package:flutter/material.dart';

// Define the color variable darkBlue
const Color darkBlue = Color.fromARGB(255, 18, 32, 47);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: darkBlue,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: MyWidget(),
        ),
      ),
    );
  }
}

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SnappingTimePicker(
      initialTime: DateTime.now(),
      onChanged: (selected) {},
      selectorLineWidth: 5.0, // Set your desired line width here
      overallWidth: 500.0, // For example, setting the width to 300.0
    );
  }
}

class SnappingTimePicker extends StatefulWidget {
  final DateTime initialTime;
  final ValueChanged<DateTime> onChanged;
  final double selectorLineWidth;
  final double? overallWidth; // Parameter for overall widget width

  SnappingTimePicker({
    Key? key,
    required this.initialTime,
    required this.onChanged,
    this.selectorLineWidth = 4.0,
    this.overallWidth,
  }) : super(key: key);

  @override
  _SnappingTimePickerState createState() => _SnappingTimePickerState();
}

class _SnappingTimePickerState extends State<SnappingTimePicker> {
  late DateTime selectedTime;
  bool isHourSelected = true;

  @override
  void initState() {
    super.initState();
    selectedTime = widget.initialTime;
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    hour = hour == 0 ? 12 : hour;
    return "${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period";
  }

  void _updateTimeBasedOnDrag(double position, double maxPosition) {
    int value;
    if (isHourSelected) {
      // Map the drag position to hour value, ensuring we don't exceed 23 hours.
      value = (position / maxPosition * 23).clamp(0, 23).round();
      _updateSelectedTime(value, selectedTime.minute);
    } else {
      // Minute logic remains the same as before, as it's working correctly.
      value = ((position / maxPosition) * 11).round() * 5;
      value = value.clamp(0, 55);
      _updateSelectedTime(selectedTime.hour, value);
    }
  }

  void _updateSelectedTime(int hours, int minutes) {
    setState(() {
      selectedTime = DateTime(
        selectedTime.year,
        selectedTime.month,
        selectedTime.day,
        hours,
        minutes,
      );
    });
    widget.onChanged(selectedTime);
  }

  @override
  Widget build(BuildContext context) {
    double width = widget.overallWidth ?? MediaQuery.of(context).size.width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isHourSelected = !isHourSelected;
            });
          },
          child: RichText(
            text: TextSpan(
              children: <TextSpan>[
                // Change the hour text color to green when hours are selected
                TextSpan(
                  text:
                      "${selectedTime.hour % 12 == 0 ? 12 : selectedTime.hour % 12}",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isHourSelected
                        ? Colors.green
                        : Colors
                            .white, // This line changes color based on selection
                  ),
                ),
                TextSpan(
                  text: ":",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Separator stays white
                  ),
                ),
                // Change the minute text color to green when minutes are selected
                TextSpan(
                  text: selectedTime.minute.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: !isHourSelected
                        ? Colors.green
                        : Colors
                            .white, // This line changes color based on selection
                  ),
                ),
                // Keep the AM/PM indicator always the same color (white in this case)
                TextSpan(
                  text: selectedTime.hour >= 12 ? ' PM' : ' AM',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // AM/PM indicator always white
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onPanUpdate: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final position = renderBox.globalToLocal(details.globalPosition);
            _updateTimeBasedOnDrag(position.dx, width);
          },
          child: CustomPaint(
            size: Size(width, 30),
            painter: _TimePickerPainter(
              linePosition: isHourSelected
                  ? selectedTime.hour / 23 * width
                  : selectedTime.minute / 55 * width,
              isHourSelected: isHourSelected,
              lineWidth: widget.selectorLineWidth,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimePickerPainter extends CustomPainter {
  final double linePosition;
  final bool isHourSelected;
  final double lineWidth;

  _TimePickerPainter({
    required this.linePosition,
    required this.isHourSelected,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = lineWidth;

    // Draw the horizontal line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      basePaint,
    );

    // Draw the notches
    final notchPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    // Determine the number of notches
    final int numNotches = isHourSelected ? 24 : 12;
    final double notchSpacing = size.width / (numNotches - 1);

    for (int i = 0; i < numNotches; i++) {
      final double offset = notchSpacing * i;
      canvas.drawLine(
        Offset(offset, size.height / 3),
        Offset(offset, 2 * size.height / 3),
        notchPaint,
      );
    }

    // Draw the selector above the notches
    final selectorPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(linePosition, 0),
      Offset(linePosition, size.height),
      selectorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimePickerPainter oldDelegate) {
    // Add isHourSelected to repaint condition if the number of notches needs to change when toggling between hours and minutes
    return oldDelegate.linePosition != linePosition ||
        oldDelegate.isHourSelected != isHourSelected;
  }
}
