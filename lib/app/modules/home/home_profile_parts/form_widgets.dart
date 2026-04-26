part of '../home_profile_tab.dart';

class _TextFieldBlock extends StatelessWidget {
  const _TextFieldBlock({
    required this.controller,
    required this.label,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleMd),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.primaryDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceLow,
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeWrapPicker extends StatelessWidget {
  const _TypeWrapPicker({
    required this.value,
    required this.items,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> items;
  final Color selectedColor;
  final Color selectedTextColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.entries
          .map(
            (entry) => ChoiceChip(
              label: Text(entry.value),
              selected: value == entry.key,
              onSelected: (_) => onChanged(entry.key),
              selectedColor: selectedColor,
              labelStyle: AppTextStyles.bodySm.copyWith(
                color: value == entry.key
                    ? selectedTextColor
                    : AppColors.bodyColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DateFieldBlock extends StatelessWidget {
  const _DateFieldBlock({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleMd),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.bodyColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilePickerBox extends StatelessWidget {
  const _FilePickerBox({
    required this.title,
    required this.emptyLabel,
    required this.fileNames,
    required this.onAddFiles,
    required this.onRemoveFile,
  });

  final String title;
  final String emptyLabel;
  final List<String> fileNames;
  final VoidCallback onAddFiles;
  final ValueChanged<int> onRemoveFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.titleMd),
              const Spacer(),
              TextButton(
                onPressed: onAddFiles,
                child: const Text('Ajouter'),
              ),
            ],
          ),
          if (fileNames.isEmpty)
            Text(
              emptyLabel,
              style: AppTextStyles.bodySm,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fileNames
                  .asMap()
                  .entries
                  .map(
                    (entry) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.categoryPinkSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_outlined,
                            size: 16,
                            color: AppColors.categoryPinkDeep,
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              entry.value,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.categoryPinkDeep,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => onRemoveFile(entry.key),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.categoryPinkDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}
