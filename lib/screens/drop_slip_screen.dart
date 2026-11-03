import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../providers/slip_provider.dart';
import '../theme/slip_theme.dart';
import '../widgets/hairline_input.dart';

class DropSlipScreen extends StatefulWidget {
  final SlipProvider provider;

  const DropSlipScreen({super.key, required this.provider});

  @override
  State<DropSlipScreen> createState() => _DropSlipScreenState();
}

class _DropSlipScreenState extends State<DropSlipScreen> {
  String _selectedTopic = AppConstants.gateTopics.first;
  final TextEditingController _subtopicController = TextEditingController();
  final TextEditingController _trapController = TextEditingController();
  final TextEditingController _fixController = TextEditingController();

  bool _hasVoiceRecording = false;
  int _audioSeconds = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subtopicController.dispose();
    _trapController.dispose();
    _fixController.dispose();
    super.dispose();
  }

  Future<void> _submitSlip() async {
    final trap = _trapController.text.trim();
    final fix = _fixController.text.trim();

    if (trap.isEmpty || fix.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PLEASE FILL BOTH THE TRAP AND THE FIX',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: SlipTheme.canvas),
          ),
          backgroundColor: SlipTheme.trapRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.provider.dropSlip(
      topic: _selectedTopic,
      subtopic: _subtopicController.text.trim().isNotEmpty
          ? _subtopicController.text.trim()
          : 'General Trap',
      trapStatement: trap,
      fixStatement: fix,
      audioDurationSeconds: _hasVoiceRecording ? _audioSeconds : 0,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SLIP DROPPED & BROADCAST TO PEER MESH',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: SlipTheme.canvas),
          ),
          backgroundColor: SlipTheme.carbon,
        ),
      );
      // Switch back to stream tab
      widget.provider.setTabIndex(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DROP A SLIP',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'LOG YOUR TEST BLUNDER TO INOCULATE PEERS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: SlipTheme.steel,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: SlipTheme.hairline, width: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'GATE CS 2027',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Topic Dropdown
              Text(
                'SUBJECT / DOMAIN',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTopic,
                    isExpanded: true,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SlipTheme.carbon,
                          fontWeight: FontWeight.w600,
                        ),
                    items: AppConstants.gateTopics.map((topic) {
                      return DropdownMenuItem(
                        value: topic,
                        child: Text(topic),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedTopic = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Subtopic Input
              HairlineInput(
                label: 'SPECIFIC TOPIC // SUB-CONCEPT',
                placeholder: 'e.g. Eigenvalues, Paging, Deadlock',
                controller: _subtopicController,
                helperText: 'OPTIONAL',
              ),
              const SizedBox(height: 20),

              // The Trap Statement
              HairlineInput(
                label: 'THE FATAL TRAP // YOUR MISTAKE',
                placeholder:
                    'What misconception made you pick the wrong option or calculate wrongly?',
                controller: _trapController,
                helperText: 'CRITICAL',
              ),
              const SizedBox(height: 20),

              // The Fix Statement
              HairlineInput(
                label: 'THE FIX // THE RIGOROUS TRUTH',
                placeholder:
                    'What is the actual theorem, formula, or counter-example?',
                controller: _fixController,
                helperText: 'ANTIDOTE',
              ),
              const SizedBox(height: 24),

              // Evidence Capture Buttons
              Text(
                'ATTACH EVIDENCE (OPTIONAL)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Scratchpad Camera Scan
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'SCRATCHPAD PHOTO ATTACHED',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: SlipTheme.canvas),
                            ),
                            backgroundColor: SlipTheme.carbon,
                          ),
                        );
                      },
                      icon: const Icon(Icons.document_scanner_outlined, size: 16),
                      label: Text(
                        'NOTEBOOK SCAN',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SlipTheme.carbon,
                        side: const BorderSide(
                            color: SlipTheme.hairline, width: 0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Voice Autopsy
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasVoiceRecording = !_hasVoiceRecording;
                          _audioSeconds = 34;
                        });
                      },
                      icon: Icon(
                        _hasVoiceRecording
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        size: 16,
                        color: _hasVoiceRecording
                            ? SlipTheme.trapRed
                            : SlipTheme.carbon,
                      ),
                      label: Text(
                        _hasVoiceRecording ? '34s VOICE NOTE' : 'VOICE AUTOPSY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _hasVoiceRecording
                                  ? SlipTheme.trapRed
                                  : SlipTheme.carbon,
                            ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SlipTheme.carbon,
                        side: BorderSide(
                          color: _hasVoiceRecording
                              ? SlipTheme.trapRed
                              : SlipTheme.hairline,
                          width: 0.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Publish Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSlip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SlipTheme.carbon,
                    foregroundColor: SlipTheme.canvas,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
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
                          'PUBLISH SLIP TO PEER MESH // AP-SOUTH-1',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: SlipTheme.canvas,
                                letterSpacing: 0.8,
                              ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
