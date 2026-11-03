import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
import '../models/slip.dart';
import '../providers/slip_provider.dart';
import '../services/native_device_service.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';
import '../widgets/hairline_input.dart';
import '../widgets/image_gallery_grid.dart';
import '../widgets/slip_card.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final SlipProvider provider;
  final VoidCallback? onSignOut;
  final String? targetUsername;
  final String? targetExamTag;

  const ProfileScreen({
    super.key,
    required this.provider,
    this.onSignOut,
    this.targetUsername,
    this.targetExamTag,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSharedGridView = false; // Reddit-style full card text feed by default (toggleable to grid)

  Map<String, bool> _permissions = {
    'camera': false,
    'notifications': false,
    'bluetooth': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final status = await NativeDeviceService.checkPermissions();
    if (mounted) {
      setState(() => _permissions = status);
    }
  }

  Future<void> _requestPermissions() async {
    final status = await NativeDeviceService.requestPermissions();
    if (mounted) {
      setState(() => _permissions = status);
    }
  }

  bool get _allPermissionsGranted =>
      _permissions.values.isNotEmpty && _permissions.values.every((v) => v == true);

  String _profileSearchQuery = '';
  String? _profileSubjectFilter;

  void _openSearchAndFilterDrawer() {
    final searchController = TextEditingController(text: _profileSearchQuery);
    String? tempSubject = _profileSubjectFilter;
    final allSubjects = GateSyllabus.getSubjectsForExam(
      widget.provider.userExams.isNotEmpty ? widget.provider.userExams.first : GateSyllabus.gateCS,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: SlipTheme.hairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SEARCH & FILTER PROFILE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: SlipTheme.carbon,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by keyword, mistake, or doubt...',
                      hintStyle: const TextStyle(fontSize: 13, color: SlipTheme.steel),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: SlipTheme.steel),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                searchController.clear();
                                setSheetState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: SlipTheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: SlipTheme.carbon, width: 1.2),
                      ),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SUBJECT FILTER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: SlipTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SlipTheme.hairline, width: 0.8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: tempSubject,
                        isExpanded: true,
                        hint: const Text('All Subjects', style: TextStyle(fontSize: 12.5, color: SlipTheme.carbon)),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Subjects (No Filter)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          ),
                          ...allSubjects.map((s) => DropdownMenuItem<String?>(
                            value: s,
                            child: Text(s, style: const TextStyle(fontSize: 12.5)),
                          )),
                        ],
                        onChanged: (val) {
                          setSheetState(() => tempSubject = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _profileSearchQuery = '';
                              _profileSubjectFilter = null;
                            });
                            Navigator.of(ctx).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SlipTheme.steel,
                            side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('RESET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _profileSearchQuery = searchController.text.trim();
                              _profileSubjectFilter = tempSubject;
                            });
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SlipTheme.carbon,
                            foregroundColor: SlipTheme.canvas,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('APPLY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          provider: widget.provider,
          onSignOut: widget.onSignOut ?? () {},
        ),
      ),
    ).then((_) {
      _checkPermissions();
      setState(() {});
    });
  }

  void _showEditPostDialog(Slip slip) {
    final trapController = TextEditingController(text: slip.trapStatement);
    final fixController = TextEditingController(text: slip.fixStatement);
    final List<String> currentImages = List.from(slip.imageUris);
    int currentAudioSec = slip.audioDurationSeconds;
    String? currentAudioPath = slip.voiceAudioUrl;
    bool isRecordingVoice = false;
    Timer? voiceTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EDIT SHARED BLUNDER',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            voiceTimer?.cancel();
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'BLUNDER TRAP STATEMENT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SlipTheme.trapRed,
                            fontSize: 9.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    HairlineInput(
                      controller: trapController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'THE FIX PRINCIPLE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SlipTheme.clearedGreen,
                            fontSize: 9.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    HairlineInput(
                      controller: fixController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),

                    // Photos Management
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ATTACHED PHOTOS (${currentImages.length})',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: SlipTheme.steel,
                                fontSize: 9.5,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final photo = await NativeDeviceService.capturePhoto();
                            if (photo != null && photo.isNotEmpty) {
                              setModalState(() => currentImages.add(photo));
                            }
                          },
                          icon: const Icon(Icons.add_a_photo_outlined, size: 14),
                          label: const Text('ADD PHOTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(
                            foregroundColor: SlipTheme.carbon,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    if (currentImages.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: currentImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(currentImages[i]),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 1,
                                  right: 1,
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() => currentImages.removeAt(i));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Voice Note Recording / Management Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isRecordingVoice
                              ? 'RECORDING... (${currentAudioSec}s)'
                              : (currentAudioSec > 0
                                  ? 'VOICE NOTE (${currentAudioSec}s)'
                                  : 'NO VOICE NOTE'),
                          style: TextStyle(
                            fontSize: 10,
                            color: isRecordingVoice ? SlipTheme.trapRed : SlipTheme.steel,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isRecordingVoice)
                          ElevatedButton(
                            onPressed: () async {
                              voiceTimer?.cancel();
                              final path = await NativeDeviceService.stopAudioRecording();
                              setModalState(() {
                                isRecordingVoice = false;
                                currentAudioPath = path;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SlipTheme.trapRed,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('STOP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                          )
                        else if (currentAudioSec > 0)
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  if (currentAudioPath != null && currentAudioPath!.isNotEmpty) {
                                    NativeDeviceService.playAudio(currentAudioPath!);
                                  }
                                },
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                child: const Text('PLAY', style: TextStyle(fontSize: 10, color: SlipTheme.carbon, fontWeight: FontWeight.w700)),
                              ),
                              TextButton(
                                onPressed: () {
                                  NativeDeviceService.stopAudio();
                                  setModalState(() {
                                    currentAudioSec = 0;
                                    currentAudioPath = null;
                                  });
                                },
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                child: const Text('REMOVE', style: TextStyle(fontSize: 10, color: SlipTheme.trapRed, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          )
                        else
                          TextButton.icon(
                            onPressed: () async {
                              final started = await NativeDeviceService.startAudioRecording();
                              if (started) {
                                setModalState(() {
                                  isRecordingVoice = true;
                                  currentAudioSec = 0;
                                });
                                voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                                  setModalState(() => currentAudioSec++);
                                });
                              }
                            },
                            icon: const Icon(Icons.mic_none_rounded, size: 14),
                            label: const Text('ADD VOICE NOTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                            style: TextButton.styleFrom(
                              foregroundColor: SlipTheme.carbon,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () async {
                          voiceTimer?.cancel();
                          final updated = slip.copyWith(
                            trapStatement: trapController.text.trim(),
                            fixStatement: fixController.text.trim(),
                            imageUris: currentImages,
                            audioDurationSeconds: currentAudioSec,
                            voiceAudioUrl: currentAudioPath,
                          );
                          await widget.provider.updateSlip(updated);
                          Navigator.of(ctx).pop();
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SlipTheme.carbon,
                          foregroundColor: SlipTheme.canvas,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('SAVE CHANGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeletePost(Slip slip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SlipTheme.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'DELETE BLUNDER POST',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this mistake slip from your shared library?',
          style: TextStyle(fontSize: 12, color: SlipTheme.steel, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: SlipTheme.steel)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.provider.deleteSlip(slip.id);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SlipTheme.trapRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  List<Slip> _filterList(List<Slip> list) {
    return list.where((s) {
      if (_profileSubjectFilter != null && _profileSubjectFilter!.isNotEmpty) {
        if (s.topic.toLowerCase() != _profileSubjectFilter!.toLowerCase()) return false;
      }
      if (_profileSearchQuery.isNotEmpty) {
        final q = _profileSearchQuery.toLowerCase();
        final matchTopic = s.topic.toLowerCase().contains(q);
        final matchSubtopic = (s.subtopic ?? '').toLowerCase().contains(q);
        final matchTrap = s.trapStatement.toLowerCase().contains(q);
        final matchFix = s.fixStatement.toLowerCase().contains(q);
        final matchTitle = (s.title ?? '').toLowerCase().contains(q);
        if (!matchTopic && !matchSubtopic && !matchTrap && !matchFix && !matchTitle) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();
    final currentUsername = service.currentUsername ?? 'peer_anonymous';
    final userExams = service.targetExams;
    final currentUserId = service.currentUserId;

    final isOwnProfile = widget.targetUsername == null || widget.targetUsername == currentUsername;
    final displayUsername = isOwnProfile ? currentUsername : widget.targetUsername!;
    final initial = displayUsername.isNotEmpty ? displayUsername.substring(0, 1).toUpperCase() : 'P';

    // Filter slips for each tab using allSlips so active topic filters don't hide profile posts
    final allSlips = widget.provider.allSlips;
    final authorSlips = allSlips.where((s) {
      if (isOwnProfile) {
        final matchesId = currentUserId != null && s.authorId == currentUserId;
        final matchesHandle = s.authorUsername != null && s.authorUsername == currentUsername;
        return matchesId || matchesHandle;
      } else {
        return s.authorUsername == widget.targetUsername;
      }
    }).toList();

    final filteredAuthorSlips = _filterList(authorSlips);
    final sharedSlips = filteredAuthorSlips;
    final clearedSlips = _filterList(isOwnProfile
        ? allSlips.where((s) => s.hasCleared).toList()
        : authorSlips.where((s) => s.hasCleared).toList());
    final savedSlips = _filterList(isOwnProfile
        ? allSlips.where((s) => s.hasKept).toList()
        : authorSlips.where((s) => s.hasKept).toList());

    final sharedDoubtsCount = sharedSlips.where((s) => s.postType == PostType.doubt).length;
    final sharedMistakesCount = sharedSlips.where((s) => s.postType == PostType.mistake).length;

    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Instagram-Style Top Bar: Back (if peer), Title, Search & Filter Menu, and Settings
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (!isOwnProfile) ...[
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_rounded, size: 22, color: SlipTheme.carbon),
                                  onPressed: () => Navigator.of(context).pop(),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '@$displayUsername',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: SlipTheme.carbon,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // 3-horizontal-lines Search & Filter Menu Icon
                              IconButton(
                                onPressed: _openSearchAndFilterDrawer,
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  size: 24,
                                  color: SlipTheme.carbon,
                                ),
                                tooltip: 'Search & Filter',
                                visualDensity: VisualDensity.compact,
                              ),
                              if (isOwnProfile)
                                IconButton(
                                  onPressed: _openSettings,
                                  icon: const Icon(
                                    Icons.settings_outlined,
                                    size: 22,
                                    color: SlipTheme.carbon,
                                  ),
                                  tooltip: 'Settings',
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. Instagram-Style Avatar + Stats Row
                      Row(
                        children: [
                          // Instagram circular avatar with user initial
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SlipTheme.surface,
                              border: Border.all(color: SlipTheme.hairline, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: SlipTheme.carbon,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),

                          // Living Stats Row (SHARED | CLEARED | SAVED)
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatBlock(
                                  label: 'SHARED',
                                  value: sharedSlips.length.toString(),
                                  sublabel: '$sharedDoubtsCount DOUBTS · $sharedMistakesCount MISTAKES',
                                ),
                                _StatBlock(
                                  label: 'CLEARED',
                                  value: clearedSlips.length.toString(),
                                  sublabel: 'MASTERED',
                                  color: SlipTheme.clearedGreen,
                                ),
                                _StatBlock(
                                  label: 'SAVED',
                                  value: savedSlips.length.toString(),
                                  sublabel: 'REVISION',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 3. User Badge & Syllabus Tag Underneath
                      Row(
                        children: [
                          Text(
                            'GATE ASPIRANT',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: SlipTheme.steel,
                                  fontSize: 9.5,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SlipTheme.carbon.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isOwnProfile
                                  ? userExams.map((e) => e.replaceAll('GATE ', '')).join(' + ')
                                  : (widget.targetExamTag ?? 'CS').replaceAll('GATE ', ''),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: SlipTheme.carbon,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: SlipTheme.hairline, height: 1),

                      // 4. Auto-hiding Permissions Banner (Own Profile only)
                      if (isOwnProfile && !_allPermissionsGranted) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SlipTheme.surface,
                            border: Border.all(color: SlipTheme.hairline, width: 0.8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'DEVICE CAPABILITIES NEEDED',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9.5,
                                          color: SlipTheme.steel,
                                        ),
                                  ),
                                  const Text(
                                    'OFFLINE MESH & ALERTS',
                                    style: TextStyle(fontSize: 8.5, color: SlipTheme.steelLight),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _MiniPermPill(label: 'Camera', ok: _permissions['camera'] == true),
                                  const SizedBox(width: 6),
                                  _MiniPermPill(label: 'Alerts', ok: _permissions['notifications'] == true),
                                  const SizedBox(width: 6),
                                  _MiniPermPill(label: 'BLE Mesh', ok: _permissions['bluetooth'] == true),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: _requestPermissions,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: SlipTheme.carbon,
                                      foregroundColor: SlipTheme.canvas,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    child: const Text('GRANT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // 4. Instagram-style 3-Tab Bar (SHARED | CLEARED | SAVED)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: SlipTheme.carbon,
                    indicatorWeight: 1.8,
                    labelColor: SlipTheme.carbon,
                    unselectedLabelColor: SlipTheme.steelLight,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_sharp, size: 20)),
                      Tab(icon: Icon(Icons.check_circle_outline_rounded, size: 20)),
                      Tab(icon: Icon(Icons.bookmark_border_rounded, size: 20)),
                    ],
                  ),
                ),
              ),
            ];
          },
          // 5. Swipable Tab Views
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: SHARED (My Logged Posts) with 3-col grid & feed toggle
              _buildSharedTab(sharedSlips),

              // TAB 2: CLEARED (Mastered traps)
              _buildClearedTab(clearedSlips),

              // TAB 3: SAVED (Bookmarked for revision)
              _buildSavedTab(savedSlips),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: SHARED POSTS ---
  Widget _buildSharedTab(List<Slip> sharedSlips) {
    if (sharedSlips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline_rounded, size: 36, color: SlipTheme.steelLight),
              const SizedBox(height: 10),
              const Text(
                'No shared mistakes yet',
                style: TextStyle(fontWeight: FontWeight.w700, color: SlipTheme.carbon),
              ),
              const SizedBox(height: 4),
              const Text(
                'Drop a blunder you fell for to inoculate fellow peers and track your personal archive here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: SlipTheme.steel),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Sub-header with toggle: Grid vs Full Feed
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${sharedSlips.length} LOGGED BLUNDERS',
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: SlipTheme.steel, letterSpacing: 0.5),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.grid_view_sharp,
                      size: 18,
                      color: _isSharedGridView ? SlipTheme.carbon : SlipTheme.steelLight,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _isSharedGridView = true),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      Icons.view_agenda_outlined,
                      size: 18,
                      color: !_isSharedGridView ? SlipTheme.carbon : SlipTheme.steelLight,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _isSharedGridView = false),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: SlipTheme.hairline, height: 1),

        Expanded(
          child: _isSharedGridView
              ? _buildSharedGrid(sharedSlips)
              : _buildSharedFeed(sharedSlips),
        ),
      ],
    );
  }

  // Instagram 3-column media grid
  Widget _buildSharedGrid(List<Slip> slips) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: slips.length,
      itemBuilder: (context, index) {
        final slip = slips[index];
        final hasImage = slip.imageUris.isNotEmpty;

        return GestureDetector(
          onTap: () => _showPostDetailModal(slip),
          child: Container(
            color: SlipTheme.surface,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.file(
                    File(slip.imageUris.first),
                    fit: BoxFit.cover,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Text(
                        slip.topic,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: SlipTheme.carbon,
                        ),
                      ),
                    ),
                  ),

                // Multi-image badge icon
                if (slip.imageUris.length > 1)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.collections_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Audio note badge
                if (slip.audioDurationSeconds > 0)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mic_rounded, size: 8, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            '${slip.audioDurationSeconds}s',
                            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Full Feed of user's shared slips with pencil edit and trash delete buttons
  Widget _buildSharedFeed(List<Slip> slips) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      itemCount: slips.length,
      itemBuilder: (context, index) {
        final slip = slips[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: SlipTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SlipTheme.hairline, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Bar with Subject, Edit & Delete Icons
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      slip.topic,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: SlipTheme.carbon,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 18, color: SlipTheme.carbon),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showEditPostDialog(slip);
                        } else if (val == 'delete') {
                          _confirmDeletePost(slip);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16, color: SlipTheme.carbon),
                              SizedBox(width: 10),
                              Text('Edit Post', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: SlipTheme.trapRed),
                              SizedBox(width: 10),
                              Text('Delete Post', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SlipTheme.trapRed)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: SlipTheme.hairline, height: 1),

              // Embedded Slip Card Content (Reddit-style full text with provider)
              SlipCard(
                index: index,
                slip: slip,
                provider: widget.provider,
                onSameTap: () => widget.provider.toggleSame(slip.id),
                onFixToggle: () => widget.provider.toggleFixRevealed(slip.id),
                onKeepTap: () => widget.provider.toggleKeep(slip.id),
                onSolveTap: () => widget.provider.toggleCleared(slip.id),
                onPassTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  // Tapping a grid item opens a detailed sheet with Edit & Delete options
  void _showPostDetailModal(Slip slip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        slip.topic,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20, color: SlipTheme.carbon),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (val) {
                          Navigator.of(ctx).pop();
                          if (val == 'edit') {
                            _showEditPostDialog(slip);
                          } else if (val == 'delete') {
                            _confirmDeletePost(slip);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16, color: SlipTheme.carbon),
                                SizedBox(width: 10),
                                Text('Edit Post', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 16, color: SlipTheme.trapRed),
                                SizedBox(width: 10),
                                Text('Delete Post', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SlipTheme.trapRed)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: SlipTheme.hairline),
                  SlipCard(
                    index: 0,
                    slip: slip,
                    provider: widget.provider,
                    onSameTap: () => widget.provider.toggleSame(slip.id),
                    onFixToggle: () => widget.provider.toggleFixRevealed(slip.id),
                    onKeepTap: () => widget.provider.toggleKeep(slip.id),
                    onSolveTap: () => widget.provider.toggleCleared(slip.id),
                    onPassTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: CLEARED (Mastered) ---
  Widget _buildClearedTab(List<Slip> clearedSlips) {
    if (clearedSlips.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 36, color: SlipTheme.steelLight),
              SizedBox(height: 10),
              Text('No cleared mistakes yet', style: TextStyle(fontWeight: FontWeight.w700, color: SlipTheme.carbon)),
              SizedBox(height: 4),
              Text(
                'When you confidently solve a trap in your daily cycle, tap the checkmark to master it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: SlipTheme.steel),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: clearedSlips.length,
      itemBuilder: (context, index) {
        final slip = clearedSlips[index];
        return SlipCard(
          index: index,
          slip: slip,
          provider: widget.provider,
          onSameTap: () => widget.provider.toggleSame(slip.id),
          onFixToggle: () => widget.provider.toggleFixRevealed(slip.id),
          onKeepTap: () => widget.provider.toggleKeep(slip.id),
          onSolveTap: () => widget.provider.toggleCleared(slip.id),
          onPassTap: () {},
        );
      },
    );
  }

  // --- TAB 3: SAVED (Revision) ---
  Widget _buildSavedTab(List<Slip> savedSlips) {
    if (savedSlips.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmark_border_rounded, size: 36, color: SlipTheme.steelLight),
              SizedBox(height: 10),
              Text('No saved mistakes yet', style: TextStyle(fontWeight: FontWeight.w700, color: SlipTheme.carbon)),
              SizedBox(height: 4),
              Text(
                'Tap the bookmark icon on any mistake in the stream to save it here for rapid revision.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: SlipTheme.steel),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: savedSlips.length,
      itemBuilder: (context, index) {
        final slip = savedSlips[index];
        return SlipCard(
          index: index,
          slip: slip,
          provider: widget.provider,
          onSameTap: () => widget.provider.toggleSame(slip.id),
          onFixToggle: () => widget.provider.toggleFixRevealed(slip.id),
          onKeepTap: () => widget.provider.toggleKeep(slip.id),
          onSolveTap: () => widget.provider.toggleCleared(slip.id),
          onPassTap: () {},
        );
      },
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color? color;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.sublabel,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: color ?? SlipTheme.carbon,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: SlipTheme.steel,
                fontSize: 9.5,
                letterSpacing: 0.6,
              ),
        ),
        if (sublabel.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: SlipTheme.steel,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniPermPill extends StatelessWidget {
  final String label;
  final bool ok;

  const _MiniPermPill({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ok ? SlipTheme.clearedGreen.withOpacity(0.08) : SlipTheme.trapRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: ok ? SlipTheme.clearedGreen : SlipTheme.trapRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: ok ? SlipTheme.clearedGreen : SlipTheme.trapRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: SlipTheme.canvas,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
