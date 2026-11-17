import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'player_controller.dart';

/// État du minuteur de sommeil : arrêt à une heure donnée, ou à la fin du titre en cours.
class SleepTimerState {
  const SleepTimerState({this.endsAt, this.endOfTrack = false});
  final DateTime? endsAt;
  final bool endOfTrack;

  bool get active => endsAt != null || endOfTrack;
}

/// Minuteur de sommeil : met la lecture en pause au bout du délai choisi.
/// Le service de lecture reste au premier plan, donc le minuteur tourne aussi écran éteint.
class SleepTimer extends Notifier<SleepTimerState> {
  Timer? _timer;
  StreamSubscription<Duration>? _posSub;

  @override
  SleepTimerState build() {
    ref.onDispose(_cancelAll);
    return const SleepTimerState();
  }

  /// Pause dans [d].
  void start(Duration d) {
    _cancelAll();
    _timer = Timer(d, _fire);
    state = SleepTimerState(endsAt: DateTime.now().add(d));
  }

  /// Pause à la fin du titre en cours ; le titre suivant est prêt au début.
  void startEndOfTrack() {
    _cancelAll();
    final p = ref.read(audioPlayerProvider);
    _posSub = p.positionStream.listen((pos) {
      final dur = p.duration;
      if (dur == null || dur == Duration.zero) return;
      if (dur - pos <= const Duration(milliseconds: 600)) _fireEndOfTrack(p);
    });
    state = const SleepTimerState(endOfTrack: true);
  }

  void cancel() {
    _cancelAll();
    state = const SleepTimerState();
  }

  void _fire() {
    ref.read(playerProvider.notifier).pause();
    cancel();
  }

  Future<void> _fireEndOfTrack(AudioPlayer p) async {
    _posSub?.cancel();
    _posSub = null;
    ref.read(playerProvider.notifier).pause();
    // Sans ça, la reprise jouerait les dernières millisecondes du titre fini.
    if (p.hasNext) await p.seek(Duration.zero, index: p.nextIndex);
    cancel();
  }

  void _cancelAll() {
    _timer?.cancel();
    _timer = null;
    _posSub?.cancel();
    _posSub = null;
  }
}

final sleepTimerProvider = NotifierProvider<SleepTimer, SleepTimerState>(SleepTimer.new);
