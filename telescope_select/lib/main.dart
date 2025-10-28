import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telescope Select Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '2D Selector Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double? _selectedWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Drag to select paper width:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            TelescopeSelect(
              widths: const [32, 34.5, 50.8, 48, 51, 72],
              onWidthChanged: (width) {
                setState(() {
                  _selectedWidth = width;
                });
              },
            ),
            const SizedBox(height: 40),
            Text(
              _selectedWidth != null
                  ? 'Selected: ${_selectedWidth!.toStringAsFixed(1)} mm'
                  : 'No selection',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 2D selection widget that allows users to select from nested rectangles
/// by dragging right/down to select larger sizes or left/up for smaller sizes.
class TelescopeSelect extends StatefulWidget {
  final List<double> widths;
  final ValueChanged<double>? onWidthChanged;
  final double pixelsPerMm;

  const TelescopeSelect({
    super.key,
    required this.widths,
    this.onWidthChanged,
    this.pixelsPerMm = 5.0, // Default scale: 5 pixels per mm
  });

  @override
  State<TelescopeSelect> createState() => _TelescopeSelectState();
}

class _TelescopeSelectState extends State<TelescopeSelect> {
  int _selectedIndex = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Start with the smallest size selected
    _selectedIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onWidthChanged?.call(widget.widths[_selectedIndex]);
    });
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    // Calculate the drag direction and distance
    // Positive delta means dragging right/down (toward larger sizes)
    // Negative delta means dragging left/up (toward smaller sizes)
    final dragDistance = details.delta.dx + details.delta.dy;

    // Threshold for snapping to next/previous size (in pixels)
    const threshold = 10.0;

    if (dragDistance > threshold && _selectedIndex < widget.widths.length - 1) {
      // Drag right/down -> select larger size
      setState(() {
        _selectedIndex++;
        widget.onWidthChanged?.call(widget.widths[_selectedIndex]);
      });
    } else if (dragDistance < -threshold && _selectedIndex > 0) {
      // Drag left/up -> select smaller size
      setState(() {
        _selectedIndex--;
        widget.onWidthChanged?.call(widget.widths[_selectedIndex]);
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort widths to ensure proper nesting (largest to smallest for rendering)
    final sortedWidths = List<double>.from(widget.widths)..sort();
    final largestWidth = sortedWidths.last;
    final containerSize = largestWidth * widget.pixelsPerMm;

    return GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: containerSize,
            height: containerSize,
            color: Colors.grey[200],
            child: Stack(
              children: [
                // Render rectangles from largest to smallest
                for (int i = sortedWidths.length - 1; i >= 0; i--)
                  _buildRectangle(sortedWidths[i], i),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRectangle(double width, int index) {
    final size = width * widget.pixelsPerMm;
    final isSelected = widget.widths[_selectedIndex] == width;
    
    // Determine color based on state
    Color rectangleColor;
    if (isSelected && _isDragging) {
      rectangleColor = Colors.green[200]!; // Pale green during drag
    } else if (isSelected) {
      rectangleColor = Colors.green[600]!; // Bold green when selected
    } else {
      rectangleColor = Colors.grey[400]!; // Grey when not selected
    }

    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: rectangleColor,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              '${width.toStringAsFixed(0)}mm',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
