import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
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
  late String _selectedExam;
  late String _selectedSubject;
  final TextEditingController _subtopicController = TextEditingController();
  final TextEditingController _trapController = TextEditingController();
  final TextEditingController _fixController = TextEditingController();

  final List<String> _attachedImages = [];
  bool _isSubmitting = false;
  bool _allowComments = true;
  bool _isPublic = true;

  // Voice note recording simulation & state
  bool _isRecordingVoice = false;
  int _voiceSeconds = 0;
  Timer? _voiceTimer;
  bool _hasVoiceNote = false;
  bool _isPlayingVoicePreview = false;

  @override
  void initState() {
    super.initState();
    final userExams = widget.provider.userExams;
    _selectedExam = userExams.isNotEmpty ? userExams.first : GateSyllabus.gateCS;
    final subjects = GateSyllabus.getSubjectsForExam(_selectedExam);
    _selectedSubject = subjects.first;
  }

  @override
  void dispose() {
    _voiceTimer?.cancel();
    _subtopicController.dispose();
    _trapController.dispose();
    _fixController.dispose();
    super.dispose();
  }

  void _onExamChanged(String exam) {
    setState(() {
      _selectedExam = exam;
      final subjects = GateSyllabus.getSubjectsForExam(exam);
      _selectedSubject = subjects.first;
      _subtopicController.clear();
    });
  }

  void _onSubjectChanged(String subject) {
    setState(() {
      _selectedSubject = subject;
      _subtopicController.clear();
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

  void _startVoiceRecording() {
    setState(() {
      _isRecordingVoice = true;
      _voiceSeconds = 0;
      _hasVoiceNote = false;
    });
    _voiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _voiceSeconds++;
        });
      }
    });
  }

  void _stopVoiceRecording() {
    _voiceTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
      _hasVoiceNote = _voiceSeconds > 0;
    });
  }

  void _deleteVoiceNote() {
    _voiceTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
      _voiceSeconds = 0;
      _hasVoiceNote = false;
      _isPlayingVoicePreview = false;
    });
  }

  void _resetForm() {
    setState(() {
      _subtopicController.clear();
      _trapController.clear();
      _fixController.clear();
      _attachedImages.clear();
      _deleteVoiceNote();
      _isSubmitting = false;
    });
  }

  void _showSuccessConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: SlipTheme.canvas,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                'BLUNDER LOGGED & SHARED',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: SlipTheme.carbon,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your mistake on "$_selectedSubject" is now inoculating peers across the mesh.',
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
                      child: const Text(
                        'DROP ANOTHER',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
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
    final trap = _trapController.text.trim();
    final fix = _fixController.text.trim();

    if (trap.isEmpty || fix.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill both the blunder trap and the fix statement.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: SlipTheme.canvas),
          ),
          backgroundColor: SlipTheme.trapRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final subtopic = _subtopicController.text.trim().isNotEmpty
        ? _subtopicController.text.trim()
        : 'General Trap';

    final success = await widget.provider.dropSlip(
      examTag: _selectedExam,
      topic: _selectedSubject,
      subtopic: subtopic,
      trapStatement: trap,
      fixStatement: fix,
      imageUris: _attachedImages,
      audioDurationSeconds: _hasVoiceNote ? _voiceSeconds : 0,
      allowComments: _allowComments,
      isPublic: _isPublic,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      // Trigger native notification
      NativeDeviceService.showNotification(
        title: 'Blunder Logged · $_selectedExam',
        body: 'Your mistake on "$_selectedSubject" is now inoculating peers.',
      );

      _showSuccessConfirmationDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableSubjects = GateSyllabus.getSubjectsForExam(_selectedExam);
    final suggestedSubtopics =
        GateSyllabus.getSubtopics(_selectedExam, _selectedSubject);

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
                'Drop a Blunder',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SlipTheme.carbon,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Log what tripped you up and the exact principle to never fall for it again.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SlipTheme.steel,
                    ),
              ),
              const SizedBox(height: 24),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 18),

              // 1. Exam Target
              Text(
                'EXAM PAPER',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: GateSyllabus.supportedExams.map((exam) {
                  final isSelected = exam == _selectedExam;
                  return ChoiceChip(
                    label: Text(
                      exam,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? SlipTheme.canvas : SlipTheme.carbon,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: SlipTheme.carbon,
                    backgroundColor: SlipTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                      side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                    ),
                    onSelected: (_) => _onExamChanged(exam),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // 2. Canonical Subject
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(3),
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

              // 3. Subtopic / Concept
              Text(
                'SPECIFIC TOPIC / CONCEPT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 8),
              HairlineInput(
                controller: _subtopicController,
                placeholder: 'e.g. Eigenvalues, Pipeline Forwarding, LR(1) Parsers',
                maxLines: 1,
              ),

              if (suggestedSubtopics.isNotEmpty) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: suggestedSubtopics.take(6).map((sub) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(
                            sub,
                            style: const TextStyle(fontSize: 10.5, color: SlipTheme.steel),
                          ),
                          backgroundColor: SlipTheme.surface,
                          side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                          padding: const EdgeInsets.all(2),
                          onPressed: () {
                            setState(() {
                              _subtopicController.text = sub;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // 4. The Blunder Trap
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

              // 5. The Fix
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

              const SizedBox(height: 24),

              // 6. Media Options: Camera & Voice Recording
              Text(
                'ATTACH EVIDENCE (PHOTOS & VOICE NOTE)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  // Camera Capture Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _capturePhoto,
                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                      label: Text(
                        _attachedImages.isEmpty
                            ? 'ADD PHOTO'
                            : 'ADD PHOTO (${_attachedImages.length})',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SlipTheme.carbon,
                        side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Voice Record Button
                  Expanded(
                    child: _isRecordingVoice
                        ? ElevatedButton.icon(
                            onPressed: _stopVoiceRecording,
                            icon: const Icon(Icons.stop_rounded, size: 16, color: Colors.white),
                            label: Text(
                              'STOP (${_voiceSeconds}s)',
                              style: const TextStyle(
                                  fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SlipTheme.trapRed,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: _hasVoiceNote ? null : _startVoiceRecording,
                            icon: Icon(
                              _hasVoiceNote ? Icons.mic_rounded : Icons.mic_none_rounded,
                              size: 16,
                              color: _hasVoiceNote ? SlipTheme.clearedGreen : SlipTheme.carbon,
                            ),
                            label: Text(
                              _hasVoiceNote ? 'RECORDED (${_voiceSeconds}s)' : 'RECORD VOICE',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _hasVoiceNote ? SlipTheme.clearedGreen : SlipTheme.carbon,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SlipTheme.carbon,
                              side: BorderSide(
                                color: _hasVoiceNote ? SlipTheme.clearedGreen : SlipTheme.hairline,
                                width: 0.8,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPlayingVoicePreview = !_isPlayingVoicePreview;
                          });
                        },
                        child: Icon(
                          _isPlayingVoicePreview
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: SlipTheme.carbon,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AudioWaveformStrip(
                          durationSeconds: _voiceSeconds,
                          isPlaying: _isPlayingVoicePreview,
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
                            borderRadius: BorderRadius.circular(3),
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

              // 7. Visibility: Public vs Private
              Text(
                'VISIBILITY & PRIVACY',
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
                      onTap: () => setState(() => _isPublic = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isPublic ? SlipTheme.carbon : SlipTheme.surface,
                          border: Border.all(
                            color: _isPublic ? SlipTheme.carbon : SlipTheme.hairline,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(3),
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
                              'PUBLIC (INOCULATE)',
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
                  const SizedBox(width: 8),
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
                          borderRadius: BorderRadius.circular(3),
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
                              'PRIVATE (LOCAL)',
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
                ],
              ),
              if (!_isPublic) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: SlipTheme.surface,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: SlipTheme.hairline, width: 0.6),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 13, color: SlipTheme.steel),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Stored only in local phone space. Note: If you uninstall the app or clear app data, private mistakes will be gone.',
                          style: TextStyle(fontSize: 10, color: SlipTheme.steel, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 8. Peer Comments Toggle Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(3),
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
                              'ALLOW PEER COMMENTS',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    color: SlipTheme.carbon,
                                  ),
                            ),
                            Text(
                              _allowComments
                                  ? 'Peers can discuss this blunder & ask questions'
                                  : 'Comments turned off for this slip',
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
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSlip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SlipTheme.carbon,
                    foregroundColor: SlipTheme.canvas,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
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
                          'DROP SLIP',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: SlipTheme.canvas,
                                letterSpacing: 0.8,
                              ),
                        ),
                ),
              ),

              // CRITICAL: Bottom spacing to prevent button occlusion by NavDock
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
