import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
import '../models/slip.dart';
import '../providers/slip_provider.dart';
import '../services/native_device_service.dart';
import '../theme/slip_theme.dart';
import '../widgets/audio_waveform_strip.dart';
import '../widgets/hairline_input.dart';

class DropSlipScreen extends StatefulWidget {
  final SlipProvider provider;

  const DropSlipScreen({super.key, required this.provider});

  @override
  State<DropSlipScreen> createState() => _DropSlipScreenState();
}

class _DropSlipScreenState extends State<DropSlipScreen> {
  PostType _activeMode = PostType.doubt;
  bool _isGeneralDoubt = false;

  late String _selectedExam;
  late String _selectedSubject;
  late String _selectedSubtopic;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _trapController = TextEditingController();
  final TextEditingController _fixController = TextEditingController();

  final List<String> _attachedImages = [];
  bool _isSubmitting = false;
  bool _allowComments = true;
  bool _isPublic = true;

  // Voice note recording state
  bool _isRecordingVoice = false;
  int _voiceSeconds = 0;
  Timer? _voiceTimer;
  bool _hasVoiceNote = false;
  String? _recordedAudioPath;
  bool _isPlayingVoicePreview = false;

  @override
  void initState() {
    super.initState();
    final userExams = widget.provider.userExams;
    _selectedExam = userExams.isNotEmpty ? userExams.first : GateSyllabus.gateCS;
    final subjects = GateSyllabus.getSubjectsForExam(_selectedExam);
    _selectedSubject = subjects.first;
    final topics = GateSyllabus.getSubtopics(_selectedExam, _selectedSubject);
    _selectedSubtopic = topics.isNotEmpty ? topics.first : 'General';
  }

  @override
  void dispose() {
    _voiceTimer?.cancel();
    _titleController.dispose();
    _trapController.dispose();
    _fixController.dispose();
    super.dispose();
  }

  void _onExamChanged(String exam) {
    setState(() {
      _selectedExam = exam;
      if (exam == 'General') {
        _isGeneralDoubt = true;
        _selectedSubject = 'General';
        _selectedSubtopic = 'General';
      } else {
        _isGeneralDoubt = false;
        final subjects = GateSyllabus.getSubjectsForExam(exam);
        _selectedSubject = subjects.first;
        final topics = GateSyllabus.getSubtopics(exam, _selectedSubject);
        _selectedSubtopic = topics.isNotEmpty ? topics.first : 'General';
      }
    });
  }

  void _onSubjectChanged(String subject) {
    setState(() {
      _selectedSubject = subject;
      final topics = GateSyllabus.getSubtopics(_selectedExam, subject);
      _selectedSubtopic = topics.isNotEmpty ? topics.first : 'General';
    });
  }

  void _onSubtopicChanged(String subtopic) {
    setState(() {
      _selectedSubtopic = subtopic;
    });
  }

  Future<void> _capturePhoto() async {
    final photoPath = await NativeDeviceService.capturePhoto();
    if (photoPath != null && photoPath.isNotEmpty) {
      setState(() {
        _attachedImages.add(photoPath);
      });
    }
  }

  Future<void> _startVoiceRecording() async {
    final started = await NativeDeviceService.startAudioRecording();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission required for audio blunder note.'),
          backgroundColor: SlipTheme.carbon,
        ),
      );
      return;
    }
    setState(() {
      _isRecordingVoice = true;
      _voiceSeconds = 0;
      _hasVoiceNote = false;
      _recordedAudioPath = null;
    });
    _voiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _voiceSeconds++;
        });
      }
    });
  }

  Future<void> _stopVoiceRecording() async {
    _voiceTimer?.cancel();
    final path = await NativeDeviceService.stopAudioRecording();
    setState(() {
      _isRecordingVoice = false;
      _recordedAudioPath = path;
      _hasVoiceNote = _voiceSeconds > 0;
    });
  }

  void _deleteVoiceNote() {
    _voiceTimer?.cancel();
    NativeDeviceService.stopAudio();
    setState(() {
      _isRecordingVoice = false;
      _voiceSeconds = 0;
      _hasVoiceNote = false;
      _recordedAudioPath = null;
      _isPlayingVoicePreview = false;
    });
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _trapController.clear();
      _fixController.clear();
      _attachedImages.clear();
      _deleteVoiceNote();
      _isSubmitting = false;
      _isGeneralDoubt = false;
      final userExams = widget.provider.userExams;
      _selectedExam = userExams.isNotEmpty ? userExams.first : GateSyllabus.gateCS;
      final subjects = GateSyllabus.getSubjectsForExam(_selectedExam);
      _selectedSubject = subjects.first;
      final topics = GateSyllabus.getSubtopics(_selectedExam, _selectedSubject);
      _selectedSubtopic = topics.isNotEmpty ? topics.first : 'General';
    });
  }

  void _showSuccessConfirmationDialog() {
    final isDoubt = _activeMode == PostType.doubt;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: SlipTheme.canvas,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Confirmation Tick Emblem
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: SlipTheme.clearedGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 32,
                    color: SlipTheme.clearedGreen,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isDoubt ? 'DOUBT POSTED TO PEERS' : 'BLUNDER LOGGED',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: SlipTheme.carbon,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isDoubt
                    ? 'Peers preparing for "$_selectedSubject" can now see and answer your question.'
                    : (_isPublic
                        ? 'Your mistake on "$_selectedSubject" is now inoculating peers.'
                        : 'Your mistake on "$_selectedSubject" is saved safely to your local device.'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SlipTheme.steel,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _resetForm();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SlipTheme.carbon,
                        side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        isDoubt ? 'ASK ANOTHER' : 'DROP ANOTHER',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _resetForm();
                        widget.provider.setTabIndex(0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SlipTheme.carbon,
                        foregroundColor: SlipTheme.canvas,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'VIEW IN STREAM',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitSlip() async {
    final isDoubt = _activeMode == PostType.doubt;
    final title = _titleController.text.trim();
    final trap = _trapController.text.trim();
    final fix = _fixController.text.trim();

    if (isDoubt) {
      if (title.isEmpty || trap.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please provide both a doubt title and detailed question context.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SlipTheme.canvas),
            ),
            backgroundColor: SlipTheme.trapRed,
          ),
        );
        return;
      }
    } else {
      if (trap.isEmpty || fix.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please describe both the blunder trap and the fix statement.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SlipTheme.canvas),
            ),
            backgroundColor: SlipTheme.trapRed,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final isGeneral = _selectedExam == 'General' || _isGeneralDoubt;
    final finalExam = isGeneral ? 'General' : _selectedExam;
    final finalSubject = isGeneral ? 'General' : _selectedSubject;
    final finalSubtopic = isGeneral ? 'General' : _selectedSubtopic;

    final success = await widget.provider.dropSlip(
      examTag: finalExam,
      topic: finalSubject,
      subtopic: finalSubtopic,
      postType: _activeMode,
      title: isDoubt ? title : null,
      trapStatement: trap,
      fixStatement: fix,
      imageUris: _attachedImages,
      voiceAudioUrl: _recordedAudioPath,
      audioDurationSeconds: _hasVoiceNote ? _voiceSeconds : 0,
      allowComments: _allowComments,
      isPublic: isDoubt ? true : _isPublic,
    );

    if (mounted) setState(() => _isSubmitting = false);

    if (success && mounted) {
      NativeDeviceService.showNotification(
        title: isDoubt
            ? (isGeneral ? 'General Doubt Posted' : 'Doubt Posted · $finalExam')
            : 'Blunder Logged · $finalExam',
        body: isDoubt
            ? (isGeneral
                ? 'Your general question is live for peer answers.'
                : 'Your question on "$finalSubject" is live for peer answers.')
            : 'Your mistake on "$finalSubject" is recorded.',
      );

      _showSuccessConfirmationDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGeneral = _selectedExam == 'General' || _isGeneralDoubt;
    final availableSubjects = isGeneral ? const ['General'] : GateSyllabus.getSubjectsForExam(_selectedExam);
    final availableSubtopics = isGeneral ? const ['General'] : GateSyllabus.getSubtopics(_selectedExam, _selectedSubject);
    final allSubtopicOptions = availableSubtopics.isNotEmpty ? availableSubtopics : const ['General'];

    // Ensure valid selections
    if (isGeneral) {
      _selectedSubject = 'General';
      _selectedSubtopic = 'General';
    } else {
      if (!availableSubjects.contains(_selectedSubject)) {
        _selectedSubject = availableSubjects.first;
      }
      if (!allSubtopicOptions.contains(_selectedSubtopic)) {
        _selectedSubtopic = allSubtopicOptions.first;
      }
    }

    final isDoubt = _activeMode == PostType.doubt;

    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Header
              Text(
                'Create Post',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SlipTheme.carbon,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                isDoubt
                    ? 'Ask peers a conceptual question or problem you are stuck on.'
                    : 'Log an exam test trap and the exact principle to inoculate yourself.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SlipTheme.steel,
                    ),
              ),
              const SizedBox(height: 18),

              // 0. Dual Mode Toggle: [ ASK A DOUBT ] | [ LOG A MISTAKE ]
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeMode = PostType.doubt;
                            _isPublic = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isDoubt ? SlipTheme.carbon : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.help_outline_rounded,
                                  size: 14,
                                  color: isDoubt ? SlipTheme.canvas : SlipTheme.steel,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'ASK A DOUBT',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: isDoubt ? SlipTheme.canvas : SlipTheme.steel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeMode = PostType.mistake;
                            _isPublic = false; // Mistakes local by default
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isDoubt ? SlipTheme.carbon : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: !isDoubt ? SlipTheme.canvas : SlipTheme.steel,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LOG A MISTAKE',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: !isDoubt ? SlipTheme.canvas : SlipTheme.steel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 18),

              // 1. Cascading Selector 1: Exam Paper Dropdown
              Text(
                'TARGET EXAM PAPER',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  color: SlipTheme.surface,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: (_selectedExam == 'General' || _isGeneralDoubt) ? 'General' : _selectedExam,
                    isExpanded: true,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SlipTheme.carbon,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                    items: [
                      ...GateSyllabus.supportedExams.map((exam) {
                        return DropdownMenuItem(
                          value: exam,
                          child: Text(exam, overflow: TextOverflow.ellipsis),
                        );
                      }),
                      const DropdownMenuItem(
                        value: 'General',
                        child: Text('General Doubt (No Subject / Any Topic)', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) _onExamChanged(val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 2. Cascading Selector 2: Subject Dropdown (hidden if General Doubt is active)
              if (!_isGeneralDoubt) ...[
                Text(
                  'SYLLABUS SUBJECT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SlipTheme.steel,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: SlipTheme.hairline, width: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    color: SlipTheme.surface,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSubject,
                      isExpanded: true,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SlipTheme.carbon,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                      items: availableSubjects.map((subj) {
                        return DropdownMenuItem(
                          value: subj,
                          child: Text(subj, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) _onSubjectChanged(val);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 3. Cascading Selector 3: Topic Dropdown (Cascaded dynamically from Subject)
                Text(
                  'SYLLABUS TOPIC',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SlipTheme.steel,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: SlipTheme.hairline, width: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    color: SlipTheme.surface,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSubtopic,
                      isExpanded: true,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SlipTheme.carbon,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                      items: allSubtopicOptions.map((top) {
                        return DropdownMenuItem(
                          value: top,
                          child: Text(top, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) _onSubtopicChanged(val);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],

              // 4. Form inputs based on Active Mode
              if (isDoubt) ...[
                // Question Title
                Text(
                  'DOUBT TITLE / CORE QUESTION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SlipTheme.carbon,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 8),
                HairlineInput(
                  controller: _titleController,
                  placeholder: 'e.g. Why is L1 cache virtually indexed in VIPT?',
                  maxLines: 1,
                ),
                const SizedBox(height: 18),

                // Question Context / Description
                Text(
                  'DETAILED CONTEXT / WHAT CONFUSED YOU',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SlipTheme.steel,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 8),
                HairlineInput(
                  controller: _trapController,
                  placeholder: 'Describe the problem statement, theorem, or calculation you need help with...',
                  maxLines: 4,
                ),
                const SizedBox(height: 18),
              ] else ...[
                // Mistake Trap
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: SlipTheme.trapRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'THE BLUNDER (WHAT TRIPPED YOU UP)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SlipTheme.trapRed,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                HairlineInput(
                  controller: _trapController,
                  placeholder: 'Describe the false assumption or conceptual trap you fell for...',
                  maxLines: 4,
                ),
                const SizedBox(height: 20),

                // Mistake Fix
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: SlipTheme.clearedGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'THE FIX (THE UNFORGETTABLE PRINCIPLE)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SlipTheme.clearedGreen,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                HairlineInput(
                  controller: _fixController,
                  placeholder: 'What is the correct, rigorous logic or rule to remember?',
                  maxLines: 4,
                ),
              ],

              const SizedBox(height: 24),

              // 5. Media Options: Camera & Mic Icons
              Row(
                children: [
                  // Camera Icon Action Button
                  InkWell(
                    onTap: _capturePhoto,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: SlipTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SlipTheme.hairline, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_camera_outlined, size: 20, color: SlipTheme.carbon),
                          if (_attachedImages.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: SlipTheme.carbon,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_attachedImages.length}',
                                style: const TextStyle(
                                  color: SlipTheme.canvas,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Mic Icon Action Button
                  InkWell(
                    onTap: () {
                      if (_isRecordingVoice) {
                        _stopVoiceRecording();
                      } else if (!_hasVoiceNote) {
                        _startVoiceRecording();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: _isRecordingVoice
                            ? SlipTheme.trapRed.withOpacity(0.08)
                            : (_hasVoiceNote ? SlipTheme.clearedGreen.withOpacity(0.08) : SlipTheme.surface),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isRecordingVoice
                              ? SlipTheme.trapRed
                              : (_hasVoiceNote ? SlipTheme.clearedGreen : SlipTheme.hairline),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isRecordingVoice
                                ? Icons.stop_rounded
                                : (_hasVoiceNote ? Icons.mic_rounded : Icons.mic_none_rounded),
                            size: 20,
                            color: _isRecordingVoice
                                ? SlipTheme.trapRed
                                : (_hasVoiceNote ? SlipTheme.clearedGreen : SlipTheme.carbon),
                          ),
                          if (_isRecordingVoice) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${_voiceSeconds}s',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: SlipTheme.trapRed,
                              ),
                            ),
                          ] else if (_hasVoiceNote) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${_voiceSeconds}s',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: SlipTheme.clearedGreen,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Voice Note Preview Bar
              if (_hasVoiceNote) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: SlipTheme.surface,
                    border: Border.all(color: SlipTheme.hairline, width: 0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AudioWaveformStrip(
                          durationSeconds: _voiceSeconds,
                          audioUrl: _recordedAudioPath,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: SlipTheme.trapRed),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _deleteVoiceNote,
                      ),
                    ],
                  ),
                ),
              ],

              // Photo Previews
              if (_attachedImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 74,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, index) {
                      final path = _attachedImages[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(path),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _attachedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // 6. Visibility: Public vs Private (for Mistakes)
              if (!isDoubt) ...[
                Text(
                  'STORAGE & PRIVACY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SlipTheme.steel,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isPublic = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isPublic ? SlipTheme.carbon : SlipTheme.surface,
                            border: Border.all(
                              color: !_isPublic ? SlipTheme.carbon : SlipTheme.hairline,
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: !_isPublic ? SlipTheme.canvas : SlipTheme.carbon,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'PRIVATE (DEVICE ONLY)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: !_isPublic ? SlipTheme.canvas : SlipTheme.carbon,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isPublic = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isPublic ? SlipTheme.carbon : SlipTheme.surface,
                            border: Border.all(
                              color: _isPublic ? SlipTheme.carbon : SlipTheme.hairline,
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.public_rounded,
                                size: 14,
                                color: _isPublic ? SlipTheme.canvas : SlipTheme.carbon,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'SHARE WITH PEERS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _isPublic ? SlipTheme.canvas : SlipTheme.carbon,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_isPublic) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: SlipTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SlipTheme.hairline, width: 0.6),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 13, color: SlipTheme.steel),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Stored in local phone storage. Note: If you uninstall the app or clear app storage, local private mistakes will be gone.',
                            style: TextStyle(fontSize: 10, color: SlipTheme.steel, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // 7. Peer Comments Toggle Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _allowComments
                              ? Icons.chat_bubble_outline_rounded
                              : Icons.comments_disabled_outlined,
                          size: 16,
                          color: _allowComments ? SlipTheme.carbon : SlipTheme.steel,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDoubt ? 'ALLOW PEER SOLUTIONS' : 'ALLOW PEER COMMENTS',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    color: SlipTheme.carbon,
                                  ),
                            ),
                            Text(
                              _allowComments
                                  ? (isDoubt ? 'Peers can answer and explain this doubt' : 'Peers can discuss this blunder & ask questions')
                                  : 'Discussions turned off',
                              style: const TextStyle(fontSize: 9.5, color: SlipTheme.steel),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: _allowComments,
                      activeColor: SlipTheme.carbon,
                      onChanged: (val) {
                        setState(() => _allowComments = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSlip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SlipTheme.carbon,
                    foregroundColor: SlipTheme.canvas,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(SlipTheme.canvas),
                          ),
                        )
                      : Text(
                          isDoubt ? 'POST DOUBT TO PEERS' : 'SAVE MISTAKE',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: SlipTheme.canvas,
                                letterSpacing: 0.8,
                              ),
                        ),
                ),
              ),

              // Bottom spacing to prevent button occlusion by NavDock
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
