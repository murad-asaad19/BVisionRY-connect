import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Phase 15 — gold-on-navy live waveform shown while recording.
///
/// Thin wrapper over the `audio_waveforms` package's [AudioWaveforms]
/// widget. The caller owns the [RecorderController] lifecycle (start,
/// stop, dispose). Width fills the available horizontal space (capped
/// by [size.width]); height is fixed at [height].
class LiveWaveform extends StatelessWidget {
  const LiveWaveform({
    super.key,
    required this.controller,
    this.height = 56,
  });

  final RecorderController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final width = MediaQuery.sizeOf(context).width - 64;
    return AudioWaveforms(
      recorderController: controller,
      size: Size(width, height),
      waveStyle: WaveStyle(
        waveColor: colors.gold,
        showMiddleLine: false,
        extendWaveform: true,
        spacing: 4.0,
        waveThickness: 2.0,
      ),
    );
  }
}
