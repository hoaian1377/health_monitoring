import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../utils/api_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ElderlyChatScreen extends StatefulWidget {
  const ElderlyChatScreen({super.key});

  @override
  State<ElderlyChatScreen> createState() => _ElderlyChatScreenState();
}

class _ElderlyChatScreenState extends State<ElderlyChatScreen> {
  final List<Map<String, String>> _messages = []; // {'role': 'user' | 'bot', 'text': '...'}
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Voice
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _tempVoiceText = '';

  // TTS
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initTTS();
    // Gửi lời chào mặc định
    _messages.add({
      'role': 'bot',
      'text': 'Chào bạn, tôi là Trợ lý sức khỏe ảo. Tôi có thể giúp gì cho bạn hôm nay? Bạn có thể nhập tin nhắn hoặc bấm giữ biểu tượng Micro để nói.'
    });
    _speak(_messages.first['text']!);
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    await _stopSpeaking();
    
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();
    
    final elderlyId = ApiService.currentRole == 'elderly' ? ApiService.currentAccountId : ApiService.currentElderlyId;
    if (elderlyId == null) {
      setState(() {
        _messages.add({'role': 'bot', 'text': 'Xin lỗi, không tìm thấy thông tin hồ sơ của bạn.'});
        _isLoading = false;
      });
      _speak('Xin lỗi, không tìm thấy thông tin hồ sơ của bạn.');
      _scrollToBottom();
      return;
    }

    final response = await ApiService.chatWithAssistant(elderlyId, text);
    if (!mounted) return;
    
    setState(() {
      _messages.add({'role': 'bot', 'text': response});
      _isLoading = false;
    });
    
    _speak(response);
    _scrollToBottom();
  }

  void _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Cần cấp quyền Microphone để sử dụng tính năng này.'))
           );
           return;
        }
      }

      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
             setState(() => _isListening = false);
             if (_tempVoiceText.isNotEmpty) {
               _sendMessage(_tempVoiceText);
               _tempVoiceText = '';
             }
          }
        },
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        await _stopSpeaking();
        _speech.listen(
          onResult: (val) => setState(() {
            _tempVoiceText = val.recognizedWords;
          }),
          localeId: 'vi_VN'
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý ảo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.volume_off),
              tooltip: 'Dừng đọc',
              onPressed: _stopSpeaking,
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFF1F5F9),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF2563EB) : Colors.white,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isUser ? const Radius.circular(4) : null,
                          bottomLeft: !isUser ? const Radius.circular(4) : null,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: isUser ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                )
              ]
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: const TextStyle(fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'Nhập câu hỏi...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onSubmitted: _sendMessage,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded),
                            color: const Color(0xFF2563EB),
                            onPressed: () => _sendMessage(_textController.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTapDown: (_) => _listen(),
                    onTapUp: (_) => _speech.stop(),
                    onTapCancel: () => _speech.stop(),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (_isListening)
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 4,
                            )
                        ]
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
