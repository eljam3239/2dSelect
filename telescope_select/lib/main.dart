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
  Offset? _dragStartPosition;
  late List<double> _sortedWidths;

  @override
  void initState() {
    super.initState();
    // Start with the smallest size selected
    _selectedIndex = 0;
    _sortedWidths = List<double>.from(widget.widths)..sort();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onWidthChanged?.call(widget.widths[_selectedIndex]);
    });
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartPosition = details.localPosition;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _dragStartPosition == null) return;

    final currentPosition = details.localPosition;
    
    // Calculate which rectangle the current position falls into
    // by checking the max of x and y coordinates (since squares)
    final positionInMm = currentPosition.dx.abs() / widget.pixelsPerMm;
    
    // Find the appropriate size based on current drag position
    int newIndex = _selectedIndex;
    
    // Check if we should snap to a larger size
    for (int i = _sortedWidths.length - 1; i >= 0; i--) {
      if (positionInMm >= _sortedWidths[i] * 0.85) { // 85% threshold for snapping
        // Find this width in the original unsorted array
        newIndex = widget.widths.indexOf(_sortedWidths[i]);
        break;
      }
    }
    
    // Only update if the selection changed
    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
        widget.onWidthChanged?.call(widget.widths[_selectedIndex]);
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
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
    final selectedWidth = widget.widths[_selectedIndex];
    final isSelected = selectedWidth == width;
    
    // A rectangle should be bold green if it's the selected size or smaller
    // (i.e., nested within the selected one)
    final shouldBeGreen = width <= selectedWidth;
    
    // Determine color based on state
    Color rectangleColor;
    if (shouldBeGreen && _isDragging) {
      rectangleColor = Colors.green[200]!; // Pale green during drag
    } else if (shouldBeGreen) {
      rectangleColor = Colors.green[600]!; // Bold green when selected or nested
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
        child: isSelected
            ? Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    '${width.toStringAsFixed(1)}mm',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
