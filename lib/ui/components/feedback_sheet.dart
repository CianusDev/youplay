import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_update.dart';
import '../../l10n/l10n.dart';
import '../../theme/sika_tokens.dart';
import 'common.dart';
import 'sika_chip.dart';

/// Adresse qui reçoit les avis envoyés par e-mail (publique : elle est dans le code source).
const feedbackEmail = 'tchandikouujashalom@gmail.com';
const _repo = 'https://github.com/CianusDev/youplay';
const _maxLength = 2000;
const _ch = MethodChannel('youplay/feedback');

/// Avis : bug ou idée. Rien ne part tout seul : l'app ouvre l'appli mail (ou GitHub) avec un
/// message pré-rempli, que la personne relit puis envoie elle-même. Aucun jeton, aucun serveur.
Future<void> showFeedbackSheet(BuildContext context) => showSikaSheet(context, (_) => const _FeedbackSheet());

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();
  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _text = TextEditingController();
  int _kind = 0; // 0 = bug, 1 = idée
  String? _error; // affiché dans la feuille (un SnackBar serait caché dessous)

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String? _message() {
    final m = _text.text.trim();
    if (m.isEmpty) {
      setState(() => _error = context.l10n.feedbackEmpty);
      return null;
    }
    return m;
  }

  Future<void> _email() async {
    final l = context.l10n;
    final m = _message();
    if (m == null) return;
    final info = await AppUpdater.diagnostics();
    final kind = _kind == 0 ? 'Bug' : 'Idea';
    final version = info.split('\n').first;
    final ok = await _ch.invokeMethod<bool>('email', {
          'to': feedbackEmail,
          'subject': '[$kind] $version',
          'body': '$m\n\n---\n$info',
        }) ??
        false;
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = l.feedbackNoMailApp(feedbackEmail));
    }
  }

  Future<void> _github() async {
    final m = _message();
    if (m == null) return;
    final info = await AppUpdater.diagnostics();
    final title = m.split('\n').first;
    final url = Uri.parse('$_repo/issues/new').replace(queryParameters: {
      'template': _kind == 0 ? 'bug_report.yml' : 'feature_request.yml',
      'title': title.length > 80 ? '${title.substring(0, 80)}…' : title,
      'description': m,
      'device': info,
    });
    final ok = await _ch.invokeMethod<bool>('open', {'url': url.toString()}) ?? false;
    if (mounted && ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.feedbackTitle, style: SikaText.display(24, ls: -0.6)),
              const SizedBox(height: 14),
              ChipRow(
                labels: [l.feedbackBug, l.feedbackIdea],
                selected: _kind,
                onSelect: (i) => setState(() => _kind = i),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _text,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                maxLength: _maxLength,
                cursorColor: SikaColors.yellow,
                style: SikaText.ui(15, w: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: _kind == 0 ? l.feedbackHintBug : l.feedbackHintIdea,
                  hintStyle: SikaText.ui(15, color: SikaColors.placeholder),
                  filled: true,
                  fillColor: SikaColors.surface2,
                  counterStyle: SikaText.meta,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(SikaRadius.lg), borderSide: BorderSide.none),
                ),
              ),
              Text(l.feedbackInfoNote, style: SikaText.meta),
              if (_error != null) ...[
                const SizedBox(height: 10),
                SelectableText(_error!, style: SikaText.ui(13, w: FontWeight.w700, color: SikaColors.yellow)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _email,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    backgroundColor: SikaColors.yellow,
                    foregroundColor: SikaColors.onYellow,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(l.feedbackEmail, style: SikaText.ui(15, w: FontWeight.w800, color: SikaColors.onYellow)),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: _github,
                  child: Text(l.feedbackGithub, style: SikaText.ui(13, w: FontWeight.w700, color: SikaColors.textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
