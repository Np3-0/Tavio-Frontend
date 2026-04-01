import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechAssistant {
  SpeechAssistant({
    required this.isVoiceEnabled,
    required this.onFinalCommand,
    required this.onListeningChanged,
    required this.onHeardCommandChanged,
  });

  final bool Function() isVoiceEnabled;
  final Future<void> Function(String command) onFinalCommand;
  final void Function(bool listening) onListeningChanged;
  final void Function(String words) onHeardCommandChanged;

  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();

  bool _voiceReady = false;
  bool _listening = false;
  bool _speaking = false;
  bool _suppressListening = false;
  bool _pausedByUser = false;
  bool _restartPending = false;
  bool _ignoreNextSpeechError = false;
  bool _reportRecognitionErrors = false;
  Completer<void>? _speechCompletion;
  BuildContext? _context;

  bool get isListening => _listening || speech.isListening;

  Future<void> init({BuildContext? context}) async {
    _context = context ?? _context;
    await _configureTtsAudio();
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.5);
    await tts.setPitch(1.0);
    await tts.setVolume(1.0);
    await tts.awaitSpeakCompletion(true);
    tts.setCompletionHandler(_completeSpeech);
    tts.setCancelHandler(_completeSpeech);
    tts.setErrorHandler(_completeSpeechError);

    final available = await speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (error) async {
        if (_ignoreNextSpeechError || _speaking || _suppressListening) {
          _ignoreNextSpeechError = false;
          return;
        }
        _setListening(false);
        if (!_reportRecognitionErrors) {
          scheduleRestart();
          return;
        }
        await announce('I could not understand that. Please try again.');
      },
    );

    _voiceReady = available;
  }

  Future<void> _configureTtsAudio() async {
    if (Platform.isAndroid) {
      await tts.setAudioAttributesForNavigation();
      await tts.setQueueMode(1);
      return;
    }

    if (Platform.isIOS) {
      await tts.setSharedInstance(true);
      await tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        <IosTextToSpeechAudioCategoryOptions>[
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );
    }
  }

  void _onSpeechStatus(String status) {
    if (_speaking || _suppressListening) return;

    final nowListening = status == 'listening';
    if (_listening != nowListening) {
      _setListening(nowListening);
    }

    final stopped = status == 'done' || status == 'notListening';
    if (stopped) {
      scheduleRestart();
    }
  }

  void scheduleRestart([BuildContext? context]) {
    _context = context ?? _context;

    if (_restartPending || _pausedByUser || _speaking || _suppressListening || !isVoiceEnabled() || !_voiceReady) {
      return;
    }

    if (speech.isListening || _listening) return;
    _restartPending = true;

    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      _restartPending = false;
      if (_pausedByUser || _speaking || _suppressListening || !isVoiceEnabled() || !_voiceReady) return;
      if (speech.isListening || _listening) return;
      await startVoiceInput(announceStart: false);
    });
  }

  Future<void> announce(String message, {BuildContext? context}) async {
    _context = context ?? _context;

    _restartPending = false;
    _speaking = true;
    _suppressListening = true;

    final activeContext = _context;
    if (activeContext != null && activeContext.mounted) {
      await SemanticsService.sendAnnouncement(
        View.of(activeContext),
        message,
        Directionality.of(activeContext),
      );
    }

    if (!isVoiceEnabled()) return;

    if (speech.isListening || _listening) {
      _ignoreNextSpeechError = true;
      await speech.stop();
      _setListening(false);
    }

    try {
      _speechCompletion = Completer<void>();
      await tts.stop();
      await tts.speak(message);
      await _speechCompletion?.future;
    } finally {
      _speechCompletion = null;
      _speaking = false;
      _suppressListening = false;
    }

    scheduleRestart();
  }

  Future<void> startVoiceInput({BuildContext? context, bool announceStart = true}) async {
    _context = context ?? _context;
    _reportRecognitionErrors = announceStart;

    if (!isVoiceEnabled()) {
      await announce('Voice assistant is disabled in settings.');
      return;
    }

    if (_speaking || _suppressListening) {
      return;
    }

    if (!_voiceReady) {
      await init();
      if (!_voiceReady) {
        await announce('Voice input is unavailable on this device.');
        return;
      }
    }

    final mic = await Permission.microphone.request();
    if (mic != PermissionStatus.granted) {
      await announce('Microphone permission is required for voice control.');
      return;
    }

    _pausedByUser = false;

    if (speech.isListening || _listening) {
      return;
    }

    if (announceStart) {
      await announce('Listening for commands.');
    }

    onHeardCommandChanged('');
    _setListening(true);

    await speech.listen(
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
      ),
      onResult: (result) {
        if (_speaking || _suppressListening) return;
        if (result.recognizedWords.isEmpty) return;
        onHeardCommandChanged(result.recognizedWords);
        if (result.finalResult) {
          _ignoreNextSpeechError = true;
          speech.stop();
          onFinalCommand(result.recognizedWords);
        }
      },
    );
  }

  Future<void> pause() async {
    _pausedByUser = true;
    _reportRecognitionErrors = false;
    _ignoreNextSpeechError = true;
    await speech.stop();
    _setListening(false);
  }

  Future<void> dispose() async {
    await speech.stop();
    await tts.stop();
  }

  void _setListening(bool value) {
    _listening = value;
    onListeningChanged(value);
  }

  void _completeSpeech() {
    if (_speechCompletion != null && !(_speechCompletion?.isCompleted ?? true)) {
      _speechCompletion!.complete();
    }
  }

  void _completeSpeechError(dynamic message) {
    _completeSpeech();
  }
}
