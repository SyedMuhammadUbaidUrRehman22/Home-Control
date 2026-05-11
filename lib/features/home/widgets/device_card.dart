import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/device_model.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final Function(bool) onToggle;

  const DeviceCard({super.key, required this.device, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: device.isOn
              ? AppColors.primary.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: device.isOn
                ? AppColors.primary.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: device.isOn ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: device.isOn
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              device.icon,
              color: device.isOn ? AppColors.primary : AppColors.textLight,
            ),
          ),
          const Spacer(),
          Text(
            device.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${device.count} Devices',
            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                device.isOn ? 'On' : 'Off',
                style: TextStyle(
                  color: device.isOn ? AppColors.primary : AppColors.textLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Transform.scale(
                scale: 0.82,
                child: Switch(value: device.isOn, onChanged: onToggle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
