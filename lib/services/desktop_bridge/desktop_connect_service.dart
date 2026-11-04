import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../constants/app_constants.dart';
import '../../constants/gate_syllabus.dart';
import '../../models/slip.dart';
import '../../providers/slip_provider.dart';
import '../native_device_service.dart';
import '../supabase_service.dart';

class DesktopConnectService {
  static final DesktopConnectService _instance = DesktopConnectService._internal();
  factory DesktopConnectService() => _instance;
  DesktopConnectService._internal();

  HttpServer? _server;
  String? _localIp;
  int _port = 8080;
  SlipProvider? _provider;
  String _sessionToken = 'slip_token_initial';

  bool get isRunning => _server != null;
  String? get serverUrl => isRunning && _localIp != null ? 'http://$_localIp:$_port' : null;
  String? get localIp => _localIp;
  int get port => _port;

  Future<String?> getDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) {
            _localIp = addr.address;
            return _localIp;
          }
        }
      }
      // Fallback
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        _localIp = interfaces.first.addresses.first.address;
        return _localIp;
      }
    } catch (e) {
      debugPrint('Error detecting local IP: $e');
    }
    _localIp = '127.0.0.1';
    return _localIp;
  }

  Future<String?> startServer(SlipProvider provider, {int port = 8080}) async {
    if (_server != null) {
      return serverUrl;
    }

    _provider = provider;
    _port = port;
    _sessionToken = 'slip_${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(0xFFFFFF).toRadixString(16)}';
    await getDeviceIp();

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
    } catch (e) {
      // If port 8080 is busy, fallback to 8888
      _port = 8888;
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
    }

    _server!.listen((HttpRequest request) {
      _handleRequest(request);
    });

    return serverUrl;
  }

  Future<void> stopServer() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
  }

  void _handleRequest(HttpRequest request) async {
    // Add CORS headers for web requests
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    if (request.method == 'GET' && (path == '/' || path == '/index.html')) {
      _serveDesktopWebPage(request);
    } else if (request.method == 'GET' && path == '/api/status') {
      final service = SupabaseService();
      final data = {
        'status': 'online',
        'username': service.currentUsername ?? 'peer',
        'exams': service.targetExams,
        'supportedExams': GateSyllabus.supportedExams,
        'version': AppConstants.appVersion,
        'requiresAuth': true,
      };
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(data));
      await request.response.close();
    } else if (request.method == 'POST' && path == '/api/auth') {
      await _handleAuth(request);
    } else if (request.method == 'POST' && path == '/api/slips') {
      await _handlePostSlip(request);
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Not Found');
      await request.response.close();
    }
  }

  Future<void> _handleAuth(HttpRequest request) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);
      final submittedPass = (data['password'] as String? ?? '').trim();

      final service = SupabaseService();
      final currentPass = service.savedPassword?.trim();

      bool isValid = false;
      if (submittedPass.isNotEmpty) {
        if (currentPass != null && currentPass.isNotEmpty) {
          isValid = (submittedPass == currentPass);
        } else if (service.client != null && service.currentUsername != null) {
          final res = await service.client!
              .from('profiles')
              .select('password_hash')
              .eq('handle', service.currentUsername!)
              .limit(1);
          if ((res as List).isNotEmpty) {
            final hash = (res.first['password_hash'] as String? ?? '').trim();
            if (hash.isNotEmpty && hash == submittedPass) {
              isValid = true;
            }
          }
        }
      }

      request.response.headers.contentType = ContentType.json;
      if (isValid) {
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          'success': true,
          'token': _sessionToken,
          'username': service.currentUsername ?? 'peer',
        }));
      } else {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write(jsonEncode({
          'success': false,
          'error': 'Incorrect account password for @${service.currentUsername ?? "user"}.',
        }));
      }
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handlePostSlip(HttpRequest request) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);

      final authHeader = request.headers.value('Authorization');
      final reqToken = (authHeader != null && authHeader.startsWith('Bearer '))
          ? authHeader.substring(7).trim()
          : (data['token'] as String? ?? '').trim();

      if (reqToken != _sessionToken) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Unauthorized. Please authenticate desktop session.'}));
        await request.response.close();
        return;
      }

      final title = data['title'] as String? ?? '';
      final trap = data['trapStatement'] as String? ?? '';
      final fix = data['fixStatement'] as String? ?? '';
      final exam = data['examTag'] as String? ?? GateSyllabus.gateCS;
      final topic = data['topic'] as String? ?? 'General';
      final subtopic = data['subtopic'] as String? ?? 'General';
      final isDoubt = data['isDoubt'] == true;
      final imageBase64 = data['imageBase64'] as String?;

      if (trap.trim().isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Trap / doubt statement cannot be empty'}));
        await request.response.close();
        return;
      }

      final attachedImages = <String>[];
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          final cleanBase64 = imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64;
          final bytes = base64Decode(cleanBase64);
          final cacheDir = await NativeDeviceService.getAppCacheDir() ?? Directory.systemTemp.path;
          final filePath = '$cacheDir/slip_desktop_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          attachedImages.add(filePath);
        } catch (e) {
          debugPrint('Error saving desktop screenshot: $e');
        }
      }

      if (_provider != null) {
        await _provider!.dropSlip(
          title: title.isNotEmpty ? title : (isDoubt ? 'Doubt: $topic' : null),
          trapStatement: trap,
          fixStatement: fix,
          examTag: exam,
          topic: topic,
          subtopic: subtopic,
          imageUris: attachedImages,
          postType: isDoubt ? PostType.doubt : PostType.mistake,
          isPublic: true,
          allowComments: true,
        );
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'success': true,
        'message': 'Blunder successfully logged into Slip app!',
      }));
      await request.response.close();
    } catch (e) {
      debugPrint('Error handling desktop slip post: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': 'Internal server error: $e'}));
      await request.response.close();
    }
  }

  void _serveDesktopWebPage(HttpRequest request) async {
    final service = SupabaseService();
    final username = service.currentUsername ?? 'peer';
    final targetExams = service.targetExams;
    final primaryExam = targetExams.isNotEmpty ? targetExams.first : GateSyllabus.gateCS;

    final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Slip Desktop Bridge — Inoculate Mistakes</title>
  <style>
    :root {
      --canvas: #FFFFFF;
      --surface: #F9F9FB;
      --carbon: #111111;
      --steel: #757575;
      --hairline: #E5E5E5;
      --trapRed: #D32F2F;
      --clearedGreen: #2E7D32;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Inter", sans-serif;
      background-color: #F4F5F7;
      color: var(--carbon);
      padding: 30px 20px;
      display: flex;
      justify-content: center;
    }
    .container {
      width: 100%;
      max-width: 760px;
      background: var(--canvas);
      border-radius: 16px;
      border: 1px solid var(--hairline);
      box-shadow: 0 4px 20px rgba(0,0,0,0.04);
      padding: 32px;
      position: relative;
    }
    .header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 1px solid var(--hairline);
      padding-bottom: 18px;
      margin-bottom: 24px;
    }
    .logo-area { display: flex; align-items: center; gap: 12px; }
    .logo-badge {
      width: 38px; height: 38px; background: var(--carbon); color: #fff;
      border-radius: 8px; display: flex; align-items: center; justify-content: center;
      font-weight: 900; font-size: 18px;
    }
    .title-area h1 { font-size: 20px; font-weight: 800; letter-spacing: -0.4px; }
    .title-area p { font-size: 12px; color: var(--steel); margin-top: 2px; }
    .status-pill {
      display: flex; align-items: center; gap: 6px; font-size: 11.5px;
      background: #E8F5E9; color: var(--clearedGreen); font-weight: 700;
      padding: 6px 12px; border-radius: 20px; border: 1px solid rgba(46,125,50,0.2);
    }
    .status-dot { width: 7px; height: 7px; background: var(--clearedGreen); border-radius: 50%; }

    /* Auth Overlay */
    .auth-overlay {
      position: fixed; top: 0; left: 0; right: 0; bottom: 0;
      background: rgba(17, 17, 17, 0.6);
      display: flex; align-items: center; justify-content: center;
      z-index: 1000;
      backdrop-filter: blur(4px);
    }
    .auth-card {
      width: 90%; max-width: 440px; background: #fff;
      border-radius: 16px; padding: 32px; border: 1px solid var(--hairline);
      box-shadow: 0 8px 30px rgba(0,0,0,0.12);
    }
    .auth-title { font-size: 16px; font-weight: 800; letter-spacing: 0.5px; margin-bottom: 6px; }
    .auth-subtitle { font-size: 12px; color: var(--steel); line-height: 1.4; margin-bottom: 20px; }
    .auth-error {
      display: none; padding: 10px 12px; border-radius: 8px;
      background: #FEE2E2; color: var(--trapRed); font-size: 12px; font-weight: 600;
      margin-bottom: 16px; border: 1px solid rgba(211,47,47,0.2);
    }
    
    .mode-toggle {
      display: flex; gap: 8px; margin-bottom: 20px;
    }
    .mode-btn {
      flex: 1; padding: 10px; border-radius: 10px; border: 1px solid var(--hairline);
      background: var(--surface); color: var(--steel); font-weight: 700; font-size: 13px;
      cursor: pointer; text-align: center; transition: all 0.15s ease;
    }
    .mode-btn.active {
      background: var(--carbon); color: #fff; border-color: var(--carbon);
    }
    
    .form-group { margin-bottom: 18px; }
    .form-label {
      display: block; font-size: 11px; font-weight: 800; color: var(--steel);
      text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px;
    }
    input[type="text"], input[type="password"], select, textarea {
      width: 100%; padding: 12px 14px; border-radius: 10px;
      border: 1px solid var(--hairline); background: var(--canvas);
      font-size: 14px; color: var(--carbon); font-family: inherit;
      outline: none; transition: border-color 0.2s;
    }
    input[readonly] { background: #f0f0f3; color: var(--steel); cursor: not-allowed; }
    input:focus, select:focus, textarea:focus {
      border-color: var(--carbon);
    }
    textarea { resize: vertical; min-height: 90px; line-height: 1.5; }
    
    .row { display: flex; gap: 14px; }
    .row > .form-group { flex: 1; }
    
    .paste-box {
      border: 2px dashed var(--hairline); border-radius: 12px;
      padding: 20px; text-align: center; background: var(--surface);
      cursor: pointer; transition: border-color 0.2s, background 0.2s;
      margin-bottom: 20px;
    }
    .paste-box.dragover, .paste-box:hover {
      border-color: var(--carbon); background: #f0f0f3;
    }
    .paste-box p { font-size: 13px; font-weight: 600; color: var(--steel); }
    .paste-box small { font-size: 11px; color: #999; display: block; margin-top: 4px; }
    
    .preview-area {
      display: none; align-items: center; justify-content: space-between;
      padding: 10px 14px; background: #fff; border: 1px solid var(--hairline);
      border-radius: 10px; margin-bottom: 20px;
    }
    .preview-info { display: flex; align-items: center; gap: 12px; }
    .preview-thumb { width: 44px; height: 44px; object-fit: cover; border-radius: 6px; }
    .remove-img {
      color: var(--trapRed); font-size: 12px; font-weight: 700; cursor: pointer;
    }

    .submit-btn {
      width: 100%; padding: 14px; background: var(--carbon); color: #fff;
      border: none; border-radius: 10px; font-size: 14px; font-weight: 800;
      letter-spacing: 0.4px; cursor: pointer; transition: opacity 0.2s;
    }
    .submit-btn:hover { opacity: 0.92; }
    .submit-btn:disabled { opacity: 0.5; cursor: not-allowed; }

    .toast {
      display: none; padding: 14px 18px; border-radius: 10px;
      background: #E8F5E9; color: var(--clearedGreen); font-size: 13px;
      font-weight: 700; margin-bottom: 20px; border: 1px solid rgba(46,125,50,0.3);
    }
  </style>
</head>
<body>
  <!-- Embedded Authentication Modal -->
  <div id="authOverlay" class="auth-overlay">
    <div class="auth-card">
      <div class="auth-title">DESKTOP AUTHENTICATION</div>
      <p class="auth-subtitle">Verify your account password to securely sync exam blunders and screenshot autopsies to @$username's phone.</p>
      
      <div id="authError" class="auth-error"></div>

      <div class="form-group">
        <label class="form-label">Phone Account Handle</label>
        <input type="text" value="@$username" readonly>
      </div>

      <div class="form-group">
        <label class="form-label">Account Password</label>
        <input type="password" id="authPasswordInput" placeholder="Enter account password" autofocus onkeydown="if(event.key==='Enter') verifyDesktopAuth()">
      </div>

      <button type="button" class="submit-btn" id="authSubmitBtn" onclick="verifyDesktopAuth()">UNLOCK DESKTOP BRIDGE</button>
    </div>
  </div>

  <div class="container">
    <div class="header">
      <div class="logo-area">
        <div class="logo-badge">S</div>
        <div class="title-area">
          <h1>Slip Desktop Bridge</h1>
          <p>Connected to @$username's Phone · <a href="javascript:void(0)" onclick="lockSession()" style="color:var(--steel); text-decoration:underline;">Lock Session</a></p>
        </div>
      </div>
      <div class="status-pill">
        <div class="status-dot"></div>
        <span>LIVE WI-FI LINK</span>
      </div>
    </div>

    <div id="toastMsg" class="toast"></div>

    <div class="mode-toggle">
      <div class="mode-btn active" id="modeMistake" onclick="setMode('mistake')">EXAM MISTAKE / TRAP</div>
      <div class="mode-btn" id="modeDoubt" onclick="setMode('doubt')">QUESTION DOUBT</div>
    </div>

    <form id="slipForm" onsubmit="submitForm(event)">
      <div class="row">
        <div class="form-group">
          <label class="form-label">Target Exam</label>
          <select id="examSelect">
            <option value="$primaryExam">$primaryExam</option>
            <option value="GATE CS">GATE CS</option>
            <option value="GATE DA">GATE DA</option>
            <option value="GATE EC">GATE EC</option>
            <option value="GATE ME">GATE ME</option>
            <option value="General">General</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Subject</label>
          <input type="text" id="subjectInput" placeholder="e.g. Operating Systems / Math" value="General">
        </div>
      </div>

      <div class="form-group" id="titleGroup" style="display:none;">
        <label class="form-label">Doubt Title / Core Question</label>
        <input type="text" id="titleInput" placeholder="e.g. Why is LRU page replacement prone to Belady anomaly?">
      </div>

      <div class="form-group">
        <label class="form-label" id="trapLabel">The Conceptual Mistake / Trap You Fell For</label>
        <textarea id="trapInput" required placeholder="Describe what went wrong in your thought process during the mock test..."></textarea>
      </div>

      <div class="form-group" id="fixGroup">
        <label class="form-label">The Fix / Correct Rigorous Logic</label>
        <textarea id="fixInput" placeholder="What is the exact formula, theorem, or edge case to remember next time?"></textarea>
      </div>

      <!-- Screenshot Clipboard Paste Area -->
      <div class="paste-box" id="pasteBox">
        <p>Click here and press <strong>Ctrl + V</strong> to paste question screenshot</p>
        <small>Or drag and drop an image file from your laptop</small>
      </div>

      <div class="preview-area" id="previewArea">
        <div class="preview-info">
          <img id="previewImg" class="preview-thumb" src="" alt="Screenshot">
          <span style="font-size:12px; font-weight:600;" id="previewText">Clipboard Screenshot</span>
        </div>
        <span class="remove-img" onclick="removeImage()">REMOVE</span>
      </div>

      <button type="submit" class="submit-btn" id="submitBtn">LOG BLUNDER TO SLIP APP</button>
    </form>
  </div>

  <script>
    let activeMode = 'mistake';
    let base64Image = null;
    let desktopToken = sessionStorage.getItem('slip_desktop_token');

    // Check existing session
    if (desktopToken) {
      document.getElementById('authOverlay').style.display = 'none';
    }

    async function verifyDesktopAuth() {
      const pass = document.getElementById('authPasswordInput').value;
      const errBox = document.getElementById('authError');
      const authBtn = document.getElementById('authSubmitBtn');
      errBox.style.display = 'none';

      if (!pass || pass.trim().length === 0) {
        errBox.textContent = 'Please enter your account password.';
        errBox.style.display = 'block';
        return;
      }

      authBtn.disabled = true;
      authBtn.textContent = 'VERIFYING...';

      try {
        const res = await fetch('/api/auth', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ password: pass })
        });
        const data = await res.json();
        if (res.ok && data.success && data.token) {
          desktopToken = data.token;
          sessionStorage.setItem('slip_desktop_token', desktopToken);
          document.getElementById('authOverlay').style.display = 'none';
        } else {
          errBox.textContent = data.error || 'Authentication failed. Please check password.';
          errBox.style.display = 'block';
        }
      } catch (e) {
        errBox.textContent = 'Could not communicate with phone: ' + e.message;
        errBox.style.display = 'block';
      } finally {
        authBtn.disabled = false;
        authBtn.textContent = 'UNLOCK DESKTOP BRIDGE';
      }
    }

    function lockSession() {
      sessionStorage.removeItem('slip_desktop_token');
      desktopToken = null;
      document.getElementById('authPasswordInput').value = '';
      document.getElementById('authOverlay').style.display = 'flex';
    }

    function setMode(mode) {
      activeMode = mode;
      document.getElementById('modeMistake').classList.toggle('active', mode === 'mistake');
      document.getElementById('modeDoubt').classList.toggle('active', mode === 'doubt');
      
      const titleGroup = document.getElementById('titleGroup');
      const fixGroup = document.getElementById('fixGroup');
      const trapLabel = document.getElementById('trapLabel');
      const submitBtn = document.getElementById('submitBtn');

      if (mode === 'doubt') {
        titleGroup.style.display = 'block';
        fixGroup.style.display = 'none';
        trapLabel.textContent = 'Doubt Context / What Confused You';
        submitBtn.textContent = 'POST DOUBT TO SLIP APP';
      } else {
        titleGroup.style.display = 'none';
        fixGroup.style.display = 'block';
        trapLabel.textContent = 'The Conceptual Mistake / Trap You Fell For';
        submitBtn.textContent = 'LOG BLUNDER TO SLIP APP';
      }
    }

    // Direct Clipboard Paste Listener (Ctrl+V)
    window.addEventListener('paste', (e) => {
      const items = (e.clipboardData || e.originalEvent.clipboardData).items;
      for (let item of items) {
        if (item.type.indexOf('image') !== -1) {
          const file = item.getAsFile();
          handleImageFile(file);
          break;
        }
      }
    });

    const pasteBox = document.getElementById('pasteBox');
    pasteBox.addEventListener('dragover', (e) => { e.preventDefault(); pasteBox.classList.add('dragover'); });
    pasteBox.addEventListener('dragleave', () => pasteBox.classList.remove('dragover'));
    pasteBox.addEventListener('drop', (e) => {
      e.preventDefault();
      pasteBox.classList.remove('dragover');
      if (e.dataTransfer.files.length > 0) {
        handleImageFile(e.dataTransfer.files[0]);
      }
    });

    function handleImageFile(file) {
      if (!file || !file.type.startsWith('image/')) return;
      const reader = new FileReader();
      reader.onload = (event) => {
        base64Image = event.target.result;
        document.getElementById('previewImg').src = base64Image;
        document.getElementById('previewText').textContent = file.name || 'Pasted Image (' + (file.size/1024).toFixed(0) + ' KB)';
        document.getElementById('previewArea').style.display = 'flex';
        pasteBox.style.display = 'none';
      };
      reader.readAsDataURL(file);
    }

    function removeImage() {
      base64Image = null;
      document.getElementById('previewArea').style.display = 'none';
      pasteBox.style.display = 'block';
    }

    async function submitForm(e) {
      e.preventDefault();
      if (!desktopToken) {
        lockSession();
        return;
      }

      const submitBtn = document.getElementById('submitBtn');
      submitBtn.disabled = true;
      submitBtn.textContent = 'SAVING TO SLIP APP...';

      const payload = {
        title: document.getElementById('titleInput').value.trim(),
        trapStatement: document.getElementById('trapInput').value.trim(),
        fixStatement: document.getElementById('fixInput').value.trim(),
        examTag: document.getElementById('examSelect').value,
        topic: document.getElementById('subjectInput').value.trim() || 'General',
        subtopic: 'General',
        isDoubt: activeMode === 'doubt',
        imageBase64: base64Image
      };

      try {
        const res = await fetch('/api/slips', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + desktopToken
          },
          body: JSON.stringify(payload)
        });
        const result = await res.json();
        if (res.ok) {
          const toast = document.getElementById('toastMsg');
          toast.textContent = (payload.isDoubt ? 'Doubt' : 'Mistake') + ' successfully logged into Slip!';
          toast.style.display = 'block';
          setTimeout(() => toast.style.display = 'none', 3500);

          document.getElementById('titleInput').value = '';
          document.getElementById('trapInput').value = '';
          document.getElementById('fixInput').value = '';
          removeImage();
        } else if (res.status === 401) {
          alert('Desktop session expired or unauthorized. Please re-enter your password.');
          lockSession();
        } else {
          alert('Error: ' + (result.error || 'Failed to save'));
        }
      } catch (err) {
        alert('Network error communicating with phone: ' + err.message);
      } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = activeMode === 'doubt' ? 'POST DOUBT TO SLIP APP' : 'LOG BLUNDER TO SLIP APP';
      }
    }
  </script>
</body>
</html>
''';

    request.response.headers.contentType = ContentType.html;
    request.response.write(html);
    await request.response.close();
  }
}
