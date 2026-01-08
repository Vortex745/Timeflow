import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../common/bouncing_widget.dart';

class NumberKeypad extends StatelessWidget {
  final Function(String) onInput;
  final VoidCallback onDelete;
  final VoidCallback onDone;

  const NumberKeypad({
    super.key,
    required this.onInput,
    required this.onDelete,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 移除固定的 padding 和 height，改用 Flexible/Expanded 自适应
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 20.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildRow(context, const ['1', '2', '3'])),
          SizedBox(height: 12.h),
          Expanded(child: _buildRow(context, const ['4', '5', '6'])),
          SizedBox(height: 12.h),
          Expanded(child: _buildRow(context, const ['7', '8', '9'])),
          SizedBox(height: 12.h),
          Expanded(
            child: Row(
              children: [
                _buildKey(context, '.', isNumber: true),
                SizedBox(width: 16.w),
                _buildKey(context, '0', isNumber: true),
                SizedBox(width: 16.w),
                _buildIconKey(context, onDelete),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // 确认大按钮
          SizedBox(
            height: 50.h, // 给按钮一个相对固定的舒适高度
            child: BouncingWidget(
              onPress: onDone,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: AppColors.shadowPrimary,
                ),
                child: Text(
                  "完成",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch, // 拉伸填满高度
      children: keys.map((k) => _buildKey(context, k)).toList(),
    );
  }

  Widget _buildKey(BuildContext context, String text, {bool isNumber = true}) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: BouncingWidget(
          onPress: () => onInput(text),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 图标按键 (删除)
  Widget _buildIconKey(BuildContext context, VoidCallback onTap) {
    final theme = Theme.of(context);
    // 显式指定 MaterialIcons 字体，解决 Web 端图标丢失问题
    const backspaceIcon = Icons.backspace;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: BouncingWidget(
          onPress: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              backspaceIcon,
              color: theme.textTheme.titleLarge?.color,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }
}
