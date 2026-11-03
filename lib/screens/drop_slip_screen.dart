import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
import '../providers/slip_provider.dart';
import '../services/native_device_service.dart';
import '../theme/slip_theme.dart';
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

  Future<void> _submitSlip() async {
    final trap = _trapController.text.trim();
    final fix = _fixController.text.trim();

    if (trap.isEmpty || fix.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill both the blunder and the fix.',
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
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      // Trigger notification confirmation
      NativeDeviceService.showNotification(
        title: 'Blunder Logged to $_selectedExam',
        body: 'Your mistake on "$_selectedSubject" is now inoculating peers.',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mistake logged and shared with peers.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: SlipTheme.canvas),
          ),
          backgroundColor: SlipTheme.carbon,
        ),
      );
      widget.provider.setTabIndex(0);
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
                'Log test blunders to inoculate yourself and your peers.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SlipTheme.steel,
                    ),
              ),
              const SizedBox(height: 24),

              // 1. Exam Paper Selector
              Text(
                'EXAM PAPER',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                    ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: GateSyllabus.supportedExams.map((exam) {
                  final isSelected = _selectedExam == exam;
                  final label = exam.replaceAll(' 2027', '');
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) _onExamChanged(exam);
                    },
                    selectedColor: SlipTheme.carbon,
                    backgroundColor: SlipTheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? SlipTheme.canvas : SlipTheme.carbon,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                      side: BorderSide(
                        color: isSelected ? SlipTheme.carbon : SlipTheme.hairline,
                        width: 0.8,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // 2. Syllabus Subject Dropdown
              Text(
                'SUBJECT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                    ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: availableSubjects.contains(_selectedSubject)
                        ? _selectedSubject
                        : availableSubjects.first,
                    isExpanded: true,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SlipTheme.carbon,
                          fontWeight: FontWeight.w600,
                        ),
                    items: availableSubjects.map((sub) {
                      return DropdownMenuItem<String>(
                        value: sub,
                        child: Text(sub),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _onSubjectChanged(val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 3. Subtopic Input + Quick Suggestions
              HairlineInput(
                label: 'SUBTOPIC / CONCEPT',
                hint: 'e.g. Eigenvalues or select below',
                controller: _subtopicController,
              ),
              if (suggestedSubtopics.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: suggestedSubtopics.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final item = suggestedSubtopics[index];
                      return ActionChip(
                        label: Text(item),
                        labelStyle: const TextStyle(
                          fontSize: 10,
                          color: SlipTheme.carbon,
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: SlipTheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                          side: const BorderSide(
                              color: SlipTheme.hairline, width: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: () {
                          setState(() {
                            _subtopicController.text = item;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // 4. The Blunder Trap
              HairlineInput(
                label: 'THE TRAP (WHAT WENT WRONG)',
                hint: 'State your misconception or calculation trap clearly...',
                maxLines: 3,
                controller: _trapController,
              ),

              const SizedBox(height: 20),

              // 5. The Fix
              HairlineInput(
                label: 'THE FIX (CONCEPTUAL TRUTH)',
                hint: 'What is the precise rule, theorem, or check to never repeat this?',
                maxLines: 3,
                controller: _fixController,
              ),

              const SizedBox(height: 20),

              // 6. Camera Photo Attachments (Multiple Images)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QUESTION / ROUGH SHEET PHOTOS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SlipTheme.steel,
                        ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _capturePhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 14),
                    label: Text(
                      _attachedImages.isEmpty ? 'SNAP PHOTO' : '+ ADD MORE',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SlipTheme.carbon,
                      side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              if (_attachedImages.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
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
                                  color: Colors.black70,
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

              const SizedBox(height: 28),

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
                            valueColor:
                                AlwaysStoppedAnimation(SlipTheme.canvas),
                          ),
                        )
                      : Text(
                          'DROP SLIP',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: SlipTheme.canvas,
                                    letterSpacing: 0.8,
                                  ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
