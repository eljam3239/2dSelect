import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final GlobalKey<_TelescopeSelectState> _telescopeKey = GlobalKey<_TelescopeSelectState>();

  void _showWidthPicker() {
    final availableWidths = const [38.0, 58.0, 80.0];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Width'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableWidths.map((width) {
              return ListTile(
                title: Text('${width.toStringAsFixed(0)} mm'),
                onTap: () {
                  _telescopeKey.currentState?.setSelectedWidth(width);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

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
              key: _telescopeKey,
              widths: const [38, 58, 80], //[32, 34.5, 50.8, 48, 51, 72],
              onWidthChanged: (width) {
                setState(() {
                  _selectedWidth = width;
                });
              },
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _showWidthPicker,
              child: Text(
                _selectedWidth != null
                    ? 'Selected: ${_selectedWidth!.toStringAsFixed(1)} mm'
                    : 'No selection',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
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
  final double heightScale; // Vertical scale factor (1.0 = square, 0.5 = half height)

  const TelescopeSelect({
    super.key,
    required this.widths,
    this.onWidthChanged,
    this.pixelsPerMm = 5.0, // Default scale: 5 pixels per mm
    this.heightScale = 0.5, // Default: square (same width and height)
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

  /// Programmatically set the selected width
  void setSelectedWidth(double width) {
    final index = widget.widths.indexOf(width);
    if (index != -1 && index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      widget.onWidthChanged?.call(widget.widths[_selectedIndex]);
      HapticFeedback.selectionClick();
    }
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
      // Trigger haptic feedback on selection change
      HapticFeedback.selectionClick();
      
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
    final containerWidth = largestWidth * widget.pixelsPerMm;
    final containerHeight = containerWidth * widget.heightScale;

    return GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: containerWidth,
            height: containerHeight,
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
    final rectWidth = width * widget.pixelsPerMm;
    final rectHeight = rectWidth * widget.heightScale;
    final selectedWidth = widget.widths[_selectedIndex];
    final isSelected = selectedWidth == width;
    
    // A rectangle should be bold green if it's the selected size or smaller
    // (i.e., nested within the selected one)
    final shouldBeGreen = width <= selectedWidth;
    final isBigger = width > selectedWidth;
    
    // Determine color based on state
    Color baseColor;
    Color borderColor;
    bool useGradient = false;
    
    if (shouldBeGreen && _isDragging) {
      baseColor = Colors.green[200]!; // Pale green during drag
      borderColor = Colors.green;
      useGradient = true; // Apply gradient to all selected and nested
    } else if (shouldBeGreen) {
      baseColor = Colors.green[600]!; // Bold green when selected or nested
      borderColor = Colors.green;
      useGradient = true; // Apply gradient to all selected and nested
    } else if (isBigger) {
      baseColor = Colors.green[50]!; // Very faint light green fill for bigger rectangles
      borderColor = Colors.green[100]!; // Very faint green outline for bigger rectangles
    } else {
      baseColor = Colors.grey[400]!; // Grey fallback
      borderColor = Colors.green;
    }

    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        width: rectWidth,
        height: rectHeight,
        decoration: BoxDecoration(
          gradient: useGradient
              ? LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    baseColor, // Darkest at bottom
                    baseColor.withOpacity(0.3), // Lighter at top
                  ],
                )
              : null,
          color: useGradient ? null : baseColor,
          border: Border(
            left: BorderSide(color: borderColor, width: 2),
            right: BorderSide(color: borderColor, width: 2),
            bottom: BorderSide(color: borderColor, width: 2),
            top: BorderSide.none, // No top border
          ),
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
