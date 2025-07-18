import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sheet.dart';
import '../utils/constants.dart';

/// Editable table widget optimized for Android phones
/// Excel-like spreadsheet editor with touch controls
class EditableTable extends StatefulWidget {
  final CustomerSheet sheet;
  final Function(CustomerSheet) onSheetChanged;
  final bool isReadOnly;
  final double cellWidth;
  final double cellHeight;

  const EditableTable({
    Key? key,
    required this.sheet,
    required this.onSheetChanged,
    this.isReadOnly = false,
    this.cellWidth = 120.0,
    this.cellHeight = 50.0,
  }) : super(key: key);

  @override
  State<EditableTable> createState() => _EditableTableState();
}

class _EditableTableState extends State<EditableTable> {
  late CustomerSheet _currentSheet;
  int? _selectedRow;
  int? _selectedColumn;
  bool _isEditing = false;

  final TextEditingController _cellController = TextEditingController();
  final FocusNode _cellFocusNode = FocusNode();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentSheet = widget.sheet;

    _cellFocusNode.addListener(() {
      if (!_cellFocusNode.hasFocus && _isEditing) {
        _finishEditing();
      }
    });
  }

  @override
  void dispose() {
    _cellController.dispose();
    _cellFocusNode.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EditableTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sheet != oldWidget.sheet) {
      _currentSheet = widget.sheet;
      _selectedRow = null;
      _selectedColumn = null;
      _isEditing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table controls
        if (!widget.isReadOnly) _buildTableControls(),

        // Selected cell info
        if (_selectedRow != null && _selectedColumn != null)
          _buildCellInfo(),

        // Table container
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Column(
              children: [
                // Column headers
                _buildColumnHeaders(),

                // Table content
                Expanded(
                  child: _buildTableContent(),
                ),
              ],
            ),
          ),
        ),

        // Table footer with actions
        if (!widget.isReadOnly) _buildTableFooter(),
      ],
    );
  }

  /// Build table controls
  Widget _buildTableControls() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        children: [
          // Add row button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 16),
              label: const Text(AppStrings.addRow, style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Add column button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addColumn,
              icon: const Icon(Icons.add, size: 16),
              label: const Text(AppStrings.addColumn, style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Delete selected
          if (_selectedRow != null || _selectedColumn != null)
            IconButton(
              onPressed: _showDeleteOptions,
              icon: const Icon(Icons.delete, color: AppColors.error),
              tooltip: 'Delete selected',
            ),
        ],
      ),
    );
  }

  /// Build selected cell info
  Widget _buildCellInfo() {
    final cellData = _currentSheet.getCell(_selectedRow!, _selectedColumn!);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        children: [
          Text(
            'Cell ${_getColumnLetter(_selectedColumn!)}${_selectedRow! + 1}:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cellData?.value ?? '',
              style: TextStyle(
                color: cellData?.isNumeric == true ? AppColors.info : AppColors.textPrimary,
              ),
            ),
          ),
          if (cellData?.isNumeric == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NUM',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build column headers
  Widget _buildColumnHeaders() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusSmall),
          topRight: Radius.circular(AppDimensions.radiusSmall),
        ),
      ),
      child: Row(
        children: [
          // Row number header
          Container(
            width: 50,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.white30),
              ),
            ),
            child: const Center(
              child: Text(
                '#',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Column headers
          Expanded(
            child: Scrollbar(
              controller: _horizontalController,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_currentSheet.columnCount, (columnIndex) {
                    final isSelected = _selectedColumn == columnIndex;

                    return Container(
                      width: widget.cellWidth,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white24 : Colors.transparent,
                        border: const Border(
                          right: BorderSide(color: Colors.white30),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _selectColumn(columnIndex),
                        child: Center(
                          child: Text(
                            _getColumnLetter(columnIndex),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build table content
  Widget _buildTableContent() {
    return Scrollbar(
      controller: _verticalController,
      child: SingleChildScrollView(
        controller: _verticalController,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row numbers
            Column(
              children: List.generate(_currentSheet.rowCount, (rowIndex) {
                final isSelected = _selectedRow == rowIndex;

                return Container(
                  width: 50,
                  height: widget.cellHeight,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.background,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.border),
                      right: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _selectRow(rowIndex),
                    child: Center(
                      child: Text(
                        '${rowIndex + 1}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Table cells
            Expanded(
              child: Scrollbar(
                controller: _horizontalController,
                scrollbarOrientation: ScrollbarOrientation.top,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: List.generate(_currentSheet.rowCount, (rowIndex) {
                      return Row(
                        children: List.generate(_currentSheet.columnCount, (columnIndex) {
                          return _buildCell(rowIndex, columnIndex);
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual cell
  Widget _buildCell(int rowIndex, int columnIndex) {
    final cellData = _currentSheet.getCell(rowIndex, columnIndex);
    final isSelected = _selectedRow == rowIndex && _selectedColumn == columnIndex;
    final isEditing = _isEditing && isSelected;

    return Container(
      width: widget.cellWidth,
      height: widget.cellHeight,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 0.5,
        ),
      ),
      child: isEditing ? _buildEditingCell() : _buildDisplayCell(cellData, rowIndex, columnIndex),
    );
  }

  /// Build cell in editing mode
  Widget _buildEditingCell() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: TextField(
        controller: _cellController,
        focusNode: _cellFocusNode,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        onSubmitted: (_) => _finishEditing(),
        textInputAction: TextInputAction.done,
      ),
    );
  }

  /// Build cell in display mode
  Widget _buildDisplayCell(CellData? cellData, int rowIndex, int columnIndex) {
    return InkWell(
      onTap: widget.isReadOnly ? null : () => _selectCell(rowIndex, columnIndex),
      onDoubleTap: widget.isReadOnly ? null : () => _startEditing(rowIndex, columnIndex),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: cellData?.isNumeric == true ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            cellData?.displayValue ?? '',
            style: TextStyle(
              fontSize: 14,
              color: cellData?.isNumeric == true ? AppColors.info : AppColors.textPrimary,
              fontWeight: cellData?.isNumeric == true ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  /// Build table footer
  Widget _buildTableFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        children: [
          Text(
            'Size: ${_currentSheet.rowCount}×${_currentSheet.columnCount}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Filled: ${_currentSheet.nonEmptyCellCount}/${_currentSheet.rowCount * _currentSheet.columnCount}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          const Text(
            'Double-tap to edit • Long-press for options',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  /// Select a cell
  void _selectCell(int rowIndex, int columnIndex) {
    setState(() {
      _selectedRow = rowIndex;
      _selectedColumn = columnIndex;
      _isEditing = false;
    });
  }

  /// Select entire row
  void _selectRow(int rowIndex) {
    setState(() {
      _selectedRow = rowIndex;
      _selectedColumn = null;
      _isEditing = false;
    });
  }

  /// Select entire column
  void _selectColumn(int columnIndex) {
    setState(() {
      _selectedRow = null;
      _selectedColumn = columnIndex;
      _isEditing = false;
    });
  }

  /// Start editing a cell
  void _startEditing(int rowIndex, int columnIndex) {
    if (widget.isReadOnly) return;

    final cellData = _currentSheet.getCell(rowIndex, columnIndex);

    setState(() {
      _selectedRow = rowIndex;
      _selectedColumn = columnIndex;
      _isEditing = true;
      _cellController.text = cellData?.value ?? '';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cellFocusNode.requestFocus();
    });
  }

  /// Finish editing and save cell value
  void _finishEditing() {
    if (!_isEditing || _selectedRow == null || _selectedColumn == null) return;

    final newValue = _cellController.text;
    final cellData = CellData.fromValue(newValue);

    final updatedSheet = _currentSheet.setCell(_selectedRow!, _selectedColumn!, cellData);

    setState(() {
      _currentSheet = updatedSheet;
      _isEditing = false;
    });

    widget.onSheetChanged(updatedSheet);

    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  /// Add new row
  void _addRow() {
    final updatedSheet = _currentSheet.addRow();
    setState(() {
      _currentSheet = updatedSheet;
    });
    widget.onSheetChanged(updatedSheet);
    HapticFeedback.lightImpact();
  }

  /// Add new column
  void _addColumn() {
    final updatedSheet = _currentSheet.addColumn();
    setState(() {
      _currentSheet = updatedSheet;
    });
    widget.onSheetChanged(updatedSheet);
    HapticFeedback.lightImpact();
  }

  /// Show delete options
  void _showDeleteOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Delete Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedRow != null && _selectedColumn == null)
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: AppColors.error),
                title: Text('Delete Row ${_selectedRow! + 1}'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteRow(_selectedRow!);
                },
              ),

            if (_selectedColumn != null && _selectedRow == null)
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: AppColors.error),
                title: Text('Delete Column ${_getColumnLetter(_selectedColumn!)}'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteColumn(_selectedColumn!);
                },
              ),

            if (_selectedRow != null && _selectedColumn != null)
              ListTile(
                leading: const Icon(Icons.clear, color: AppColors.warning),
                title: const Text('Clear Cell Content'),
                onTap: () {
                  Navigator.pop(context);
                  _clearCell(_selectedRow!, _selectedColumn!);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Delete row
  void _deleteRow(int rowIndex) {
    final updatedSheet = _currentSheet.removeRow(rowIndex);
    setState(() {
      _currentSheet = updatedSheet;
      _selectedRow = null;
      _selectedColumn = null;
    });
    widget.onSheetChanged(updatedSheet);
    HapticFeedback.mediumImpact();
  }

  /// Delete column
  void _deleteColumn(int columnIndex) {
    final updatedSheet = _currentSheet.removeColumn(columnIndex);
    setState(() {
      _currentSheet = updatedSheet;
      _selectedRow = null;
      _selectedColumn = null;
    });
    widget.onSheetChanged(updatedSheet);
    HapticFeedback.mediumImpact();
  }

  /// Clear cell content
  void _clearCell(int rowIndex, int columnIndex) {
    final updatedSheet = _currentSheet.setCell(rowIndex, columnIndex, CellData.empty());
    setState(() {
      _currentSheet = updatedSheet;
    });
    widget.onSheetChanged(updatedSheet);
    HapticFeedback.lightImpact();
  }

  /// Get column letter (A, B, C, ...)
  String _getColumnLetter(int columnIndex) {
    String result = '';
    int index = columnIndex;

    while (index >= 0) {
      result = String.fromCharCode(65 + (index % 26)) + result;
      index = (index ~/ 26) - 1;
    }

    return result;
  }
}