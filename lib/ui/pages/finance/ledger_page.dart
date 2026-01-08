import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Add this import
import '../../widgets/custom_dialog.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../providers/finance_provider.dart';
import '../../../../data/models/finance_record.dart';

// --- Custom Sliding Segmented Control ---
class SlidingSegmentControl extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onValueChanged;
  final List<String> labels;

  const SlidingSegmentControl({
    super.key,
    required this.selectedIndex,
    required this.onValueChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          // Swipe Left -> Next
          if (selectedIndex < labels.length - 1) {
            onValueChanged(selectedIndex + 1);
          }
        } else if (details.primaryVelocity! > 0) {
          // Swipe Right -> Previous
          if (selectedIndex > 0) {
            onValueChanged(selectedIndex - 1);
          }
        }
      },
      child: Container(
        height: 48.h,
        width: 240.w,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background animated pill
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: selectedIndex == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: 120.w,
                height: 48.h, // Match container height
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
            ),
            // Labels
            Row(
              children: List.generate(labels.length, (index) {
                final isSelected = selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onValueChanged(index),
                    behavior: HitTestBehavior
                        .translucent, // Allow swipe to pass through if needed, but here tap takes precedence?
                    // Actually, simpler: separate tap and swipe.
                    // Swipe is on parent, Tap is on child.
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                        child: Text(labels[index]),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  int _selectedIndex = 0; // 0: Details, 1: Chart
  late PageController _pageController;
  int _touchedIndex = -1;

  // Filter states

  // Wait, usually "Ledger" defaults to THIS MONTH.
  // Let's refine: Default is "IsSameMonth". If user picks a specific day, it becomes "IsSameDay".

  DateTime _currentMonth = DateTime.now(); // Used for month navigation
  bool _isDayFilterMode =
      false; // Toggle between "Whole Month" vs "Specific Day"
  DateTime _specificDay = DateTime.now();

  String? _selectedCategory; // null = All

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSegmentChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Filter Logic
  List<FinanceRecord> _getFilteredRecords(List<FinanceRecord> all) {
    return all.where((r) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.dateMs);

      bool dateMatch;
      if (_isDayFilterMode) {
        // Match specific day
        dateMatch =
            date.year == _specificDay.year &&
            date.month == _specificDay.month &&
            date.day == _specificDay.day;
      } else {
        // Match whole month
        dateMatch =
            date.year == _currentMonth.year &&
            date.month == _currentMonth.month;
      }

      if (!dateMatch) return false;
      if (_selectedCategory != null && r.category != _selectedCategory)
        return false;

      return true;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        initialMonth: _currentMonth,
        initialSpecificDay: _specificDay,
        isDayMode: _isDayFilterMode,
        initialCategory: _selectedCategory,
        onApply: (month, day, isDayMode, category) {
          setState(() {
            _currentMonth = month;
            _specificDay = day;
            _isDayFilterMode = isDayMode;
            _selectedCategory = category;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // Remove default title to center the custom segment control nicely?
        // Or keep title "Ledger" and put segment control below?
        // User image shows: Title "账本" (Ledger) in center.
        // And the segment control is floating below header?
        // Let's put segment control in the bottom slot of AppBar (preferred size).
        title: Text(
          "账本",
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).iconTheme.color,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_alt,
              color: Theme.of(context).primaryColor,
              size: 22.sp,
            ),
            onPressed: _showFilterSheet,
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: SlidingSegmentControl(
              selectedIndex: _selectedIndex,
              labels: const ["明细", "图表"],
              onValueChanged: _onSegmentChanged,
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe if strict toggle needed, but swipe is nice
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [_buildRecordList(), _buildChartAnalysis()],
      ),
    );
  }

  Widget _buildRecordList() {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        final filtered = _getFilteredRecords(provider.records);

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48.sp,
                  color: Theme.of(context).disabledColor,
                ),
                SizedBox(height: 12.h),
                Text(
                  "暂无相关记录",
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ],
            ),
          );
        }

        final Map<String, List<FinanceRecord>> grouped = {};
        for (var record in filtered) {
          final dateKey = DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.fromMillisecondsSinceEpoch(record.dateMs));
          if (grouped[dateKey] == null) grouped[dateKey] = [];
          grouped[dateKey]!.add(record);
        }

        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: EdgeInsets.all(20.w),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final dateKey = sortedKeys[index];
            final records = grouped[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: 4.w,
                    bottom: 12.h,
                    top: index == 0 ? 0 : 16.h,
                  ),
                  child: Text(
                    _formatDateHeader(dateKey),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                ),
                ...records.map(
                  (record) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildListItem(record),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDateHeader(String dateKey) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

    if (dateKey == today) return "今天";
    if (dateKey == yesterday) return "昨天";

    final date = DateTime.parse(dateKey);
    return DateFormat("MM月dd日").format(date);
  }

  Widget _buildListItem(FinanceRecord record) {
    final date = DateTime.fromMillisecondsSinceEpoch(record.dateMs);
    final timeStr = DateFormat('HH:mm').format(date);
    final iconData = AppCategories.getIcon(record.category);
    final iconColor = AppCategories.getColor(record.category);

    return Slidable(
      key: Key(record.id.toString()),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) async {
              final confirmed = await showCustomDialog<bool>(
                context: context,
                builder: (ctx) => CustomDialog(
                  title: "删除记录",
                  content: const Text("确定要删除这条账单记录吗？"),
                  confirmText: "删除",
                  confirmColor: Colors.red,
                  onConfirm: () => Navigator.of(ctx).pop(true),
                  onCancel: () => Navigator.of(ctx).pop(false),
                ),
              );

              if (confirmed == true && record.id != null) {
                if (context.mounted) {
                  context.read<FinanceProvider>().deleteRecord(record.id!);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("记录已删除")));
                }
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            ),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.category,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                      if (record.note.isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            record.note,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              "${record.isExpense ? '-' : '+'} ${record.amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: record.isExpense
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : const Color(0xFF00B894),
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartAnalysis() {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        final filtered = _getFilteredRecords(provider.records);
        final expenseRecords = filtered.where((r) => r.isExpense).toList();

        if (expenseRecords.isEmpty) {
          return Center(
            child: Text(
              "暂无支出记录",
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
          );
        }

        final Map<String, double> categoryAmounts = {};
        double totalExpense = 0;
        for (var r in expenseRecords) {
          categoryAmounts[r.category] =
              (categoryAmounts[r.category] ?? 0) + r.amount;
          totalExpense += r.amount;
        }

        final sortedEntries = categoryAmounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final List<PieChartSectionData> sections = [];
        int sectionIndex = 0;

        for (var entry in sortedEntries) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = amount / totalExpense;
          final color = AppCategories.getColor(category);
          final isTouched = sectionIndex == _touchedIndex;

          sections.add(
            PieChartSectionData(
              color: color,
              value: amount,
              title: '${(percentage * 100).toStringAsFixed(0)}%',
              radius: isTouched ? 65.r : 55.r,
              titleStyle: TextStyle(
                fontSize: isTouched ? 14.sp : 11.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              badgeWidget: isTouched ? _buildBadge(category, color) : null,
              badgePositionPercentageOffset: 1.1,
            ),
          );
          sectionIndex++;
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(20.h),
                height: 300.h,
                child: RepaintBoundary(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40.r,
                      sectionsSpace: 4,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 300),
                    swapAnimationCurve: Curves.easeInOut,
                  ),
                ),
              ),

              ...sortedEntries.map((e) {
                final color = AppCategories.getColor(e.key);
                final percentage = e.value / totalExpense;

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 6.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [BoxShadow(offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Boxed Percentage
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          "${(percentage * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      SizedBox(
                        width: 80.w,
                        child: Text(
                          "¥${e.value.toStringAsFixed(2)}",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime initialSpecificDay;
  final bool isDayMode;
  final String? initialCategory;
  final Function(DateTime month, DateTime day, bool isDayMode, String? category)
  onApply;

  const _FilterSheet({
    required this.initialMonth,
    required this.initialSpecificDay,
    required this.isDayMode,
    required this.initialCategory,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTime _currentMonth; // For month navigation
  late DateTime _selectedDay; // Specific day selection
  late bool _isDayMode;
  late String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth;
    _selectedDay = widget.initialSpecificDay;
    _isDayMode = widget.isDayMode;
    _selectedCategory = widget.initialCategory;
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + offset,
      );
      // Reset day mode if changing month? Or keep it?
      // User might want to navigate to new month to pick a day.
    });
  }

  Future<void> _pickDate() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        DateTime tempDate = _selectedDay;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 600.h,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "取消",
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                        Text(
                          "选择日期",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedDay = tempDate;
                              _isDayMode = true; // Auto switch to day mode
                              _currentMonth = DateTime(
                                tempDate.year,
                                tempDate.month,
                              );
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            "确定",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CalendarDatePicker(
                      initialDate: tempDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      onDateChanged: (val) {
                        setModalState(() {
                          tempDate = DateTime(
                            val.year,
                            val.month,
                            val.day,
                            tempDate.hour,
                            tempDate.minute,
                          );
                        });
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: 150.h,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: tempDate,
                      use24hFormat: true,
                      onDateTimeChanged: (val) {
                        setModalState(() {
                          tempDate = DateTime(
                            tempDate.year,
                            tempDate.month,
                            tempDate.day,
                            val.hour,
                            val.minute,
                          );
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.all(24.w),
      height: 600.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          Text(
            "日期筛选",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),

          // Date Filter Toggles
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDayMode = false),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: !_isDayMode
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: !_isDayMode
                          ? null
                          : Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "按月选择",
                      style: TextStyle(
                        color: !_isDayMode
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDayMode = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: _isDayMode
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: _isDayMode
                          ? null
                          : Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "按日选择",
                      style: TextStyle(
                        color: _isDayMode
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          if (!_isDayMode)
            // Month Selector UI
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    DateFormat('yyyy年MM月').format(_currentMonth),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            )
          else
            // Day Selector UI
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      DateFormat('yyyy年MM月dd日').format(_selectedDay),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 24.h),

          Text(
            "分类筛选",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),

          Expanded(
            child: GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              children: [
                _buildCategoryItem("全部", Icons.all_inclusive, null),
                ...AppCategories.expenseList.map(
                  (c) => _buildCategoryItem(c, AppCategories.getIcon(c), c),
                ),
                ...AppCategories.incomeList.map(
                  (c) => _buildCategoryItem(c, AppCategories.getIcon(c), c),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(
                  _currentMonth,
                  _selectedDay,
                  _isDayMode,
                  _selectedCategory,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                "确认筛选",
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon, String? value) {
    final isSelected = _selectedCategory == value;
    final color = value == null
        ? Theme.of(context).primaryColor
        : AppCategories.getColor(value ?? "");

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 20.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: isSelected
                  ? Theme.of(context).textTheme.bodyLarge?.color
                  : Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
