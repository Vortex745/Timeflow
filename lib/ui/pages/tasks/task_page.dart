import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../providers/task_provider.dart';
import '../../../data/models/task.dart';
import '../../common/bouncing_widget.dart';
import 'widgets/add_task_sheet.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../widgets/custom_dialog.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                if (provider.tasks.isEmpty) return _buildEmptyState();

                // Group tasks
                final grouped = _groupTasks(provider.tasks);
                final keys = grouped.keys.toList();

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 120.h),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    final tasks = grouped[key]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                        ),
                        ...tasks
                            .map(
                              (task) => Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: _buildTaskItem(task),
                              ),
                            )
                            .toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Grouping Logic
  Map<String, List<Task>> _groupTasks(List<Task> tasks) {
    final Map<String, List<Task>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Sort: Date asc (null last), then ID desc
    final sorted = List<Task>.from(tasks)
      ..sort((a, b) {
        if (a.dueDateMs == null && b.dueDateMs == null)
          return (b.id ?? 0).compareTo(a.id ?? 0);
        if (a.dueDateMs == null) return 1;
        if (b.dueDateMs == null) return -1;
        return a.dueDateMs!.compareTo(b.dueDateMs!);
      });

    for (var task in sorted) {
      String key;
      if (task.dueDateMs == null) {
        key = "无日期";
      } else {
        final date = DateTime.fromMillisecondsSinceEpoch(task.dueDateMs!);
        final taskDay = DateTime(date.year, date.month, date.day);

        if (taskDay.isAtSameMomentAs(today)) {
          key = "今天";
        } else if (taskDay.isAtSameMomentAs(tomorrow)) {
          key = "明天";
        } else if (taskDay.isBefore(today)) {
          key = "已过期";
        } else {
          key = DateFormat('MM月dd日').format(date);
        }
      }

      if (groups[key] == null) groups[key] = [];
      groups[key]!.add(task);
    }

    // Custom sort keys?
    // "Today" -> "Tomorrow" -> specific dates -> "No Date" -> "Expired"?
    // Or just let map insertion order handle it if we sort tasks first?
    // Map doesn't guarantee order. Let's return a LinkedHashMap or just careful construction.
    // Actually, simpler to just iterate locally.

    // Let's force a specific order for keys: Expired, Today, Tomorrow, Future Dates, No Date
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        if (a == "已过期") return -1;
        if (b == "已过期") return 1;
        if (a == "今天") return -1;
        if (b == "今天") return 1;
        if (a == "明天") return -1;
        if (b == "明天") return 1;
        if (a == "无日期") return 1;
        if (b == "无日期") return -1;
        return a.compareTo(
          b,
        ); // Date strings comparison works okay for 'MM-dd' but better parse
      });

    final Map<String, List<Task>> result = {};
    for (var key in sortedKeys) {
      result[key] = groups[key]!;
    }
    return result;
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi, TimeFlow! 🎯",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "待办清单",
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          BouncingWidget(
            onPress: _showAddTaskSheet,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add,
                    color: Theme.of(context).primaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    "添加",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
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

  Widget _buildTaskItem(Task task) {
    return Slidable(
      key: Key(task.id.toString()),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) async {
              final confirmed = await showCustomDialog<bool>(
                context: context,
                builder: (ctx) => CustomDialog(
                  title: "删除任务",
                  content: const Text("确定要删除这个任务吗？"),
                  confirmText: "删除",
                  confirmColor: Colors.red,
                  onConfirm: () => Navigator.of(ctx).pop(true),
                  onCancel: () => Navigator.of(ctx).pop(false),
                ),
              );

              if (confirmed == true) {
                if (context.mounted) {
                  context.read<TaskProvider>().deleteTask(task.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("已删除: ${task.title}"),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20.r),
              bottomRight: Radius.circular(20.r),
            ),
          ),
        ],
      ),
      child: BouncingWidget(
        scaleFactor: 0.98,
        onPress: () => context.read<TaskProvider>().toggleTask(task),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: task.isDone
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
            border: task.isDone
                ? Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                task.isDone
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: task.isDone
                    ? Theme.of(context).primaryColor
                    : Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.3),
                size: 24.sp,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: task.isDone
                            ? Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.5)
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        fontWeight: task.isDone
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                    if (task.dueDateMs != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12.sp,
                            color: task.isDone
                                ? Theme.of(context).textTheme.bodyMedium?.color
                                : Theme.of(context).primaryColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            DateFormat('HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                task.dueDateMs!,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: task.isDone
                                  ? Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.5)
                                  : Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 80.sp,
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
          SizedBox(height: 16.h),
          Text(
            "所有任务都搞定啦！",
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.5),
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}
