import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_categories.dart';
import '../../../../providers/finance_provider.dart';
import '../../../../data/models/finance_record.dart';
import 'number_keypad.dart';
import '../../../widgets/custom_dialog.dart';

class AddRecordSheet extends StatefulWidget {
  const AddRecordSheet({super.key});

  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet>
    with SingleTickerProviderStateMixin {
  String _amount = "0";
  bool _isExpense = true;
  String _category = "餐饮";
  bool _showKeyboard = false;

  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  late AnimationController _tabController;
  late Animation<Alignment> _tabAnimation;

  @override
  void initState() {
    super.initState();
    _category = AppCategories.expenseList[0];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _showKeyboard = true);
    });

    _tabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tabAnimation =
        AlignmentTween(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).animate(
          CurvedAnimation(parent: _tabController, curve: Curves.easeInOutCubic),
        );

    _noteFocusNode.addListener(() {
      if (_noteFocusNode.hasFocus) {
        setState(() => _showKeyboard = false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _toggleType(bool isExpense) {
    if (_isExpense == isExpense) return;
    setState(() {
      _isExpense = isExpense;
      _category = isExpense
          ? AppCategories.expenseList[0]
          : AppCategories.incomeList[0];
    });
    if (!isExpense) {
      _tabController.forward();
    } else {
      _tabController.reverse();
    }
  }

  void _handleInput(String value) {
    if (value == "." && _amount.contains(".")) return;
    if (_amount == "0" && value != ".") {
      setState(() => _amount = value);
    } else {
      if (_amount.length < 10) setState(() => _amount += value);
    }
  }

  void _handleDelete() {
    if (_amount.length > 1) {
      setState(() => _amount = _amount.substring(0, _amount.length - 1));
    } else {
      setState(() => _amount = "0");
    }
  }

  void _handleDone() {
    final amountVal = double.tryParse(_amount);
    if (amountVal == null || amountVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("请输入有效金额哟 ~"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    final newRecord = FinanceRecord(
      amount: amountVal,
      category: _category,
      dateMs: _selectedDate.millisecondsSinceEpoch,
      isExpense: _isExpense,
      note: _noteController.text,
    );
    context.read<FinanceProvider>().addRecord(newRecord);
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    setState(() => _showKeyboard = false);
    _noteFocusNode.unfocus();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow taller sheet
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        DateTime tempDate = _selectedDate;
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
                          "选择时间",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedDate = tempDate);
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
                        // Note: CupertinoDatePicker in time mode usually returns arbitrary date with correct time.
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

    setState(() => _showKeyboard = true);
  }

  @override
  Widget build(BuildContext context) {
    const keypadHeight = 290.0;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            GestureDetector(
              onTap: () {
                _noteFocusNode.unfocus();
                setState(() => _showKeyboard = true);
              },
              child: _buildAmountDisplay(),
            ),
            SizedBox(height: 4.h),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.15, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildCategoryGrid(key: ValueKey<bool>(_isExpense)),
              ),
            ),

            _buildMetaInfoRow(),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: _showKeyboard ? keypadHeight.h : 0,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: _showKeyboard
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ]
                    : [],
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  height: keypadHeight.h,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: NumberKeypad(
                      onInput: _handleInput,
                      onDelete: _handleDelete,
                      onDone: _handleDone,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  Icons.close,
                  size: 24.sp,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
          _buildTypeToggle(),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // Swipe Right -> Expense
          _toggleType(true);
        } else if (details.primaryVelocity! < 0) {
          // Swipe Left -> Income
          _toggleType(false);
        }
      },
      child: Container(
        width: 200.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _tabAnimation,
              builder: (context, child) {
                return Align(
                  alignment: _tabAnimation.value,
                  child: Container(
                    width: 100.w,
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior
                        .translucent, // Ensure touches pass through
                    onTap: () => _toggleType(true),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        "支出",
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: _isExpense
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _toggleType(false),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        "收入",
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: !_isExpense
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        children: [
          Text(
            "金额",
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Text(
                  "¥",
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              Text(
                _amount,
                style: TextStyle(
                  fontSize: 56.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid({required Key key}) {
    final List<String> categories = _isExpense
        ? [...AppCategories.expenseList, "其他"]
        : [...AppCategories.incomeList, "其他"];

    return GridView.builder(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.72,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _category == category;
        final iconData = category == "其他"
            ? Icons.more_horiz
            : AppCategories.getIcon(category);
        final iconColor = category == "其他"
            ? Colors.grey
            : AppCategories.getColor(category);

        return GestureDetector(
          onTap: () => setState(() => _category = category),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: isSelected ? iconColor : iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: iconColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  iconData,
                  color: isSelected ? Colors.white : iconColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                category,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isSelected
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaInfoRow() {
    final dateStr = DateFormat("MM/dd").format(_selectedDate);

    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.06), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16.sp,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _editNote,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: _noteController.text.isNotEmpty
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(18.r),
                border: _noteController.text.isNotEmpty
                    ? Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 18.sp,
                    color: _noteController.text.isNotEmpty
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  SizedBox(width: 4.w),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 120.w),
                    child: Text(
                      _noteController.text.isEmpty
                          ? "添加备注"
                          : _noteController.text,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: _noteController.text.isNotEmpty
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editNote() async {
    final TextEditingController tempController = TextEditingController(
      text: _noteController.text,
    );

    final result = await showCustomDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CustomDialog(
        title: "添加备注",
        content: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: TextField(
            controller: tempController,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "写点什么...",
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.5),
                fontSize: 14.sp,
              ),
              border: InputBorder.none,
            ),
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        onConfirm: () => Navigator.pop(ctx, tempController.text),
        onCancel: () => Navigator.pop(ctx),
      ),
    );

    if (result != null) {
      _noteController.text = result;
      if (!_showKeyboard) {
        setState(() => _showKeyboard = true);
      }
    }
  }
}
