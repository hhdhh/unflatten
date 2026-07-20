import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/unflatten_theme.dart';
import '../../application/camera_lab_controller.dart';
import '../../domain/camera_recipe.dart';

class CameraLabSectionLabel extends StatelessWidget {
  const CameraLabSectionLabel({
    super.key,
    required this.label,
    this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: UnflattenColors.fgSubtle,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            height: 1.2,
          ),
        ),
        const Spacer(),
        if (value != null)
          Text(
            value!,
            style: const TextStyle(
              color: UnflattenColors.fgMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'JetBrains Mono',
              height: 1.1,
            ),
          ),
      ],
    );
  }
}

class CameraLabTuningSlider extends ConsumerWidget {
  const CameraLabTuningSlider({
    super.key,
    required this.parameter,
    required this.value,
  });

  final TuningParameter parameter;
  final double value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cameraLabProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CameraLabSectionLabel(
            label: parameter.label,
            value: value.toStringAsFixed(2),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: UnflattenColors.acid,
              inactiveTrackColor: UnflattenColors.hairline,
              thumbColor: UnflattenColors.fg,
              overlayColor: UnflattenColors.acid.withValues(alpha: 0.16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(parameter.min, parameter.max).toDouble(),
              min: parameter.min,
              max: parameter.max,
              onChangeStart: (_) => controller.beginHistoryTransaction(),
              onChanged: (next) => controller.setTuning(parameter, next),
              onChangeEnd: (_) => controller.endHistoryTransaction(),
            ),
          ),
        ],
      ),
    );
  }
}

class CameraLabSeedEditor extends StatefulWidget {
  const CameraLabSeedEditor({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onRandomize,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onRandomize;

  @override
  State<CameraLabSeedEditor> createState() => _CameraLabSeedEditorState();
}

class _CameraLabSeedEditorState extends State<CameraLabSeedEditor> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatSeed(widget.value));
  }

  @override
  void didUpdateWidget(covariant CameraLabSeedEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      final text = _formatSeed(widget.value);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  static String _formatSeed(int value) =>
      value.toRadixString(16).toUpperCase().padLeft(8, '0');

  void _commit() {
    final value = int.tryParse(_controller.text, radix: 16);
    if (value == null) {
      setState(() => _errorText = '请输入 1–8 位十六进制数');
      return;
    }
    setState(() => _errorText = null);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CameraLabSectionLabel(label: '缺陷 Seed · HEX'),
        const SizedBox(height: 9),
        TextField(
          key: const Key('seed-input'),
          controller: _controller,
          focusNode: _focusNode,
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
            LengthLimitingTextInputFormatter(8),
          ],
          style: const TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 1.2,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixText: '0x',
            counterText: '',
            errorText: _errorText,
            filled: true,
            fillColor: UnflattenColors.raised,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: UnflattenColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: UnflattenColors.line),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                _focusNode.unfocus();
                widget.onRandomize();
              },
              tooltip: '重新随机',
              icon: const Icon(Icons.casino_outlined),
            ),
          ),
          onChanged: (_) {},
          onSubmitted: (_) => _commit(),
          onTapOutside: (_) => _commit(),
        ),
      ],
    );
  }
}

class CameraLabRecipeFacts extends StatelessWidget {
  const CameraLabRecipeFacts({super.key, required this.recipe});

  final CameraRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final body = recipe.body;
    final lens = recipe.lens;
    final medium = recipe.medium;
    final capture = recipe.capture;
    final condition = recipe.condition;
    final profile = body.profile.toUpperCase();
    final rows = <_FactRow>[
      _FactRow('机身', '$profile · ${lens.focalLengthMm.round()}MM'),
      _FactRow('焦段', lens.profile.toUpperCase()),
      _FactRow('曝光偏置', '${capture.exposureBias > 0 ? '+' : ''}${capture.exposureBias.toStringAsFixed(2)} EV'),
      _FactRow('白平衡', '${capture.whiteBalance > 0 ? '+' : ''}${capture.whiteBalance.toStringAsFixed(2)}'),
      _FactRow('色彩', '饱和 ${medium.saturation.toStringAsFixed(2)} · 暖度 ${medium.warmth.toStringAsFixed(2)}'),
      _FactRow('缺陷', '尘 ${(condition.dust * 100).round()} · 划痕 ${(condition.scratches * 100).round()} · 漏光 ${(condition.lightLeak * 100).round()}'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: UnflattenColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UnflattenColors.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CameraLabSectionLabel(label: '配方档案'),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: UnflattenColors.fgSubtle,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: UnflattenColors.fg,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class CameraLabInspector extends ConsumerWidget {
  const CameraLabInspector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cameraLabProvider);
    final controller = ref.read(cameraLabProvider.notifier);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 22,
        22,
        compact ? 20 : 22,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CameraLabSectionLabel(label: 'CAMERA DNA'),
                    const SizedBox(height: 6),
                    Text(
                      state.recipe.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: UnflattenColors.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: UnflattenTokens.hairline),
                          ),
                          child: Text(
                            '#${state.recipe.seed.toRadixString(16).toUpperCase().padLeft(8, '0').substring(0, 6)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: UnflattenColors.fgMuted,
                              letterSpacing: 0.6,
                              fontFamily: 'JetBrains Mono',
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${state.recipe.body.profile.toString().toUpperCase()} · ${state.recipe.lens.focalLengthMm.round()}MM',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: UnflattenColors.fgSubtle,
                              letterSpacing: 0.4,
                              fontFamily: 'JetBrains Mono',
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: controller.resetTuning,
                tooltip: '重置参数',
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            state.recipe.description,
            style: const TextStyle(
              color: UnflattenColors.fgMuted,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          CameraLabSectionLabel(
            label: '滤镜强度',
            value: '${(state.intensity * 100).round()}%',
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: UnflattenColors.acid,
              inactiveTrackColor: UnflattenColors.hairline,
              thumbColor: UnflattenColors.fg,
              overlayColor: UnflattenColors.acid.withValues(alpha: 0.16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: state.intensity,
              onChangeStart: (_) => controller.beginHistoryTransaction(),
              onChanged: controller.setIntensity,
              onChangeEnd: (_) => controller.endHistoryTransaction(),
            ),
          ),
          const SizedBox(height: 14),
          for (final parameter in TuningParameter.values)
            CameraLabTuningSlider(
              parameter: parameter,
              value: _valueFor(state.tuning, parameter),
            ),
          const SizedBox(height: 14),
          CameraLabSeedEditor(
            value: state.seed,
            onChanged: controller.setSeed,
            onRandomize: controller.randomizeSeed,
          ),
          const SizedBox(height: 8),
          Text(
            'SEED ${state.seed.toRadixString(16).toUpperCase().padLeft(8, '0')}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: UnflattenColors.fgSubtle,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          const CameraLabSectionLabel(label: '语义保护意图'),
          const SizedBox(height: 8),
          const Text(
            '模型接入后，这些区域将减少色偏、模糊和纹理覆盖。',
            style: TextStyle(
              color: UnflattenColors.fgMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final region in SemanticRegion.values)
                _RegionChip(
                  region: region,
                  selected: state.protectedRegions.contains(region),
                ),
            ],
          ),
          const SizedBox(height: 24),
          CameraLabRecipeFacts(recipe: state.recipe),
        ],
      ),
    );
  }
}

class _RegionChip extends ConsumerWidget {
  const _RegionChip({required this.region, required this.selected});

  final SemanticRegion region;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedContainer(
      duration: UnflattenMotion.fast,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? UnflattenColors.acid.withValues(alpha: 0.16)
            : UnflattenColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? UnflattenColors.acid : UnflattenColors.hairline,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => ref
              .read(cameraLabProvider.notifier)
              .toggleProtectedRegion(region),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(
              region.label,
              style: TextStyle(
                color: selected ? UnflattenColors.fg : UnflattenColors.fgMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _valueFor(CameraTuning tuning, TuningParameter parameter) =>
    switch (parameter) {
      TuningParameter.exposure => tuning.exposure,
      TuningParameter.contrast => tuning.contrast,
      TuningParameter.saturation => tuning.saturation,
      TuningParameter.warmth => tuning.warmth,
      TuningParameter.grain => tuning.grain,
      TuningParameter.vignette => tuning.vignette,
      TuningParameter.bloom => tuning.bloom,
      TuningParameter.flash => tuning.flash,
    };
