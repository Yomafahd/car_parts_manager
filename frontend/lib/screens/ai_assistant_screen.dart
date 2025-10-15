import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:text_to_speech/text_to_speech.dart';

import '../services/egyptian_nlp_service.dart';
import '../services/media_ai_service.dart';
import '../services/diagnostic_service.dart';
import '../models/vehicle_profile.dart';
import '../services/smart_recommendation_service.dart';
import '../models/maintenance_record.dart';
import '../services/predictive_maintenance_service.dart';
import '../services/api_registry_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'api_manager_screen.dart';
import '../services/ai_backend_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantState();
}

class _AIAssistantState extends State<AIAssistantScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final TextToSpeech _textToSpeech = TextToSpeech();
  final TextEditingController _textController = TextEditingController();

  String _recognizedText = '';
  bool _isListening = false;
  bool _isProcessing = false;
  bool _speechAvailable = false;
  final List<Map<String, dynamic>> _conversation = [];
  // أولوية المرحلة الأرخص: اجعل المزود الافتراضي OpenRouter بموديل اقتصادي
  String _selectedProvider = 'openrouter';
  String _selectedModel = 'qwen/qwen-2.5-vl-32b-instruct:free';
  bool _isBudgetProfile = true; // مفتاح التبديل: اقتصادي ↔ أفضل جودة
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadAISettings();
  }

  Future<void> _loadAISettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('ai_provider');
      final model = prefs.getString('ai_model');
      final isBudget = prefs.getBool('ai_profile_budget');
      setState(() {
        if (provider != null && provider.isNotEmpty) _selectedProvider = provider;
        if (model != null && model.isNotEmpty) _selectedModel = model;
        if (isBudget != null) _isBudgetProfile = isBudget;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveAISettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_provider', _selectedProvider);
      await prefs.setString('ai_model', _selectedModel);
      await prefs.setBool('ai_profile_budget', _isBudgetProfile);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speechToText.initialize();
    } catch (_) {
      _speechAvailable = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (_isListening) return;
    if (!_speechAvailable) {
      // لا تتوفر الخدمة؛ تجاهل
      return;
    }
    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    await _speechToText.listen(onResult: (result) {
      if (!mounted) return;
      setState(() {
        _recognizedText = result.recognizedWords;
      });
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (!mounted) return;
    setState(() {
      _isListening = false;
    });
    if (_recognizedText.isNotEmpty) {
      _processUserInput(_recognizedText);
    }
  }

  Future<void> _processUserInput(String text) async {
    setState(() {
      _isProcessing = true;
      _conversation.add({
        'text': text,
        'isUser': true,
        'time': DateTime.now(),
      });
    });

    final intent = await EgyptianNLPService.advancedUnderstanding(text);
    final response = await _generateResponse(intent, text);

    if (!mounted) return;
    setState(() {
      _conversation.add({
        'text': response,
        'isUser': false,
        'time': DateTime.now(),
      });
      _isProcessing = false;
    });

    try {
      _textToSpeech.speak(response);
    } catch (_) {
      // تجاهل أخطاء TTS
    }
  }

  Future<String> _generateResponse(Map<String, dynamic> intent, String originalText) async {
    final String intentType = (intent['intent'] ?? 'general_query').toString();
    switch (intentType) {
      case 'need_part':
        final partType = intent['entities']?['part_type'] ?? 'غير محدد';
        return 'محتاج مساعدة بخصوص $partType؟ عندنا تشكيلة كويسة من قطع $partType. تحب أعرض أفضل الخيارات؟';
      case 'price_inquiry':
        return 'أسعارنا تنافسية. علشان أحدد السعر بدقة، من فضلك اذكر اسم القطعة كامل والموديل.';
      case 'location_query':
        return 'فروعنا في القاهرة والإسكندرية والجيزة. تحب عنوان فرع معين؟';
      default:
        // محاولة تشخيص مبدئي إذا احتوى النص على كلمات دالة
        if (originalText.contains('تشخيص') || originalText.contains('عطل') || originalText.contains('مشكل') || originalText.contains('صوت')) {
          final dr = await DiagnosticService.diagnoseFromText(originalText);
          final causes = dr.probableCauses.map((e) => '• $e').join('\n');
          final parts = dr.suggestedParts.map((m) => '- ${m['name']} (${m['category'] ?? 'غير مصنّف'})').join('\n');
          return '${dr.summary}\n\nأسباب محتملة:\n$causes\n\nقطع مقترحة من المخزون:\n${parts.isEmpty ? 'لا توجد اقتراحات حالياً' : parts}';
        }
        return 'أهلاً بك! أقدر أساعدك في البحث عن قطع، الأسعار، الفروع، أو أي استفسار تاني. تحب تبدأ بإيه؟';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد الذكي - يفهم العامية المصرية'),
        backgroundColor: Colors.deepPurple[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.health_and_safety),
            onPressed: _checkAIStatus,
            tooltip: 'فحص حالة الذكاء',
          ),
          if ((AuthService.currentUser?.role == UserRole.owner) || (AuthService.currentUser?.role == UserRole.manager))
            IconButton(
              icon: const Icon(Icons.settings_applications),
              tooltip: 'إدارة مزوّدي APIs',
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ApiManagerScreen()));
                setState(() {});
              },
            ),
          IconButton(
            icon: const Icon(Icons.image_outlined),
            onPressed: _generateImageFromPrompt,
            tooltip: 'توليد صورة',
          ),
          IconButton(
            icon: const Icon(Icons.photo_camera),
            onPressed: _handleImageInput,
            tooltip: 'تحليل صورة',
          ),
          IconButton(
            icon: const Icon(Icons.build_circle),
            onPressed: _triggerDiagnosticFromPrompt,
            tooltip: 'تشخيص ذكي',
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb),
            onPressed: _runSmartRecommendations,
            tooltip: 'توصيات ذكية',
          ),
          IconButton(
            icon: const Icon(Icons.engineering),
            onPressed: _runPredictiveMaintenance,
            tooltip: 'صيانة تنبؤية',
          ),
        ],
      ),
      body: Column(
        children: [
          // Provider selector and error surface
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildProviderSelector(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _conversation.length,
              itemBuilder: (context, index) {
                final message = _conversation.reversed.toList()[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isProcessing) const LinearProgressIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Future<void> _checkAIStatus() async {
    final res = await AIBackendService.getStatus();
    if (!mounted) return;
    if (res['success'] == true) {
      final ai = (res['ai'] as Map?)?.cast<String, dynamic>() ?? {};
      final lines = <String>[
        'الوضع التشغيلي للذكاء الاصطناعي:',
        '• وضع المحاكاة: ${ai['mock_mode'] == true ? 'مفعّل' : 'متوقف'}',
        '• مفتاح OpenRouter: ${ai['openrouter_key'] == true ? 'موجود' : 'غير موجود'}',
        '• OpenAI: ${ai['openai_key'] == true ? 'متاح' : 'غير متاح'}',
        '• Stability: ${ai['stability_key'] == true ? 'متاح' : 'غير متاح'}',
        '• HuggingFace: ${ai['hf_key'] == true ? 'متاح' : 'غير متاح'}',
      ];
      setState(() {
        _conversation.add({
          'text': lines.join('\n'),
          'isUser': false,
          'time': DateTime.now(),
        });
      });
    } else {
      final err = (res['error'] ?? 'تعذّر فحص الحالة').toString();
      setState(() {
        _conversation.add({
          'text': 'فشل فحص حالة الذكاء: $err',
          'isUser': false,
          'time': DateTime.now(),
        });
      });
    }
  }

  // في ai_assistant_screen.dart - إضافة واجهة اختيار المزود
  Widget _buildProviderSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعدادات الذكاء الاصطناعي',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            // مفتاح تبديل سريع بين بروفايل اقتصادي وأفضل جودة
            Align(
              alignment: Alignment.centerLeft,
              child: ToggleButtons(
                isSelected: [_isBudgetProfile, !_isBudgetProfile],
                onPressed: (int index) {
                  setState(() {
                    _isBudgetProfile = (index == 0);
                    _applyProfileDefaults();
                    _lastError = null;
                  });
                  _saveAISettings();
                },
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                selectedColor: Colors.white,
                fillColor: Colors.deepPurple,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('اقتصادي'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('أفضل جودة'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _selectedProvider,
                    items: const [
                      DropdownMenuItem(value: 'mock', child: Text('🔄 وضع المحاكاة')),
                      DropdownMenuItem(value: 'huggingface', child: Text('🤗 Hugging Face')),
                      DropdownMenuItem(value: 'openrouter', child: Text('🔗 OpenRouter')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProvider = value ?? 'mock';
                        _lastError = null; // reset on change
                        // اضبط موديلات افتراضية مناسبة حسب المزود
                        if (_selectedProvider == 'openrouter') {
                          // موديلات رؤية رخيصة وقوية
                          if (!_openrouterVisionModels.contains(_selectedModel)) {
                            _selectedModel = 'google/gemini-1.5-flash';
                          }
                        } else if (_selectedProvider == 'huggingface') {
                          // موديلات وصف صور شائعة على HF (قد تتطلب إعداد Endpoint خاص)
                          if (!_huggingfaceCaptionModels.contains(_selectedModel)) {
                            _selectedModel = 'nlpconnect/vit-gpt2-image-captioning';
                          }
                        } else {
                          _selectedModel = 'mock';
                        }
                      });
                      _saveAISettings();
                    },
                    decoration: const InputDecoration(
                      labelText: 'اختر المزود',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // اختيار الموديل (يعتمد على المزود)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _selectedModel,
                    items: _modelItemsForProvider(),
                    onChanged: (_selectedProvider == 'mock')
                        ? null
                        : (value) {
                            setState(() {
                              _selectedModel = value ?? _selectedModel;
                              _lastError = null;
                            });
                            _saveAISettings();
                          },
                    decoration: const InputDecoration(
                      labelText: 'اختر الموديل (اقتصادي افتراضياً)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (_lastError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'خطأ: ${_lastError!}',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // قائمة موديلات الرؤية المقترحة لمزود OpenRouter (أولوية الأرخص)
  static const List<String> _openrouterVisionModels = [
    'qwen/qwen-2.5-vl-32b-instruct:free', // مجاني وممتاز للرؤية
    'google/gemini-1.5-flash',
    'openai/gpt-4o-mini',
    'openai/gpt-4o',
    'meta-llama/llama-3.2-vision-instruct',
  ];

  // قائمة موديلات وصف الصور الشائعة على Hugging Face
  static const List<String> _huggingfaceCaptionModels = [
    'nlpconnect/vit-gpt2-image-captioning',
    'Salesforce/blip-image-captioning-large',
    'microsoft/git-large-coco',
  ];

  List<DropdownMenuItem<String>> _modelItemsForProvider() {
    if (_selectedProvider == 'openrouter') {
      return _openrouterVisionModels
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList();
    }
    if (_selectedProvider == 'huggingface') {
      return _huggingfaceCaptionModels
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList();
    }
    // mock
    return [
      const DropdownMenuItem(value: 'mock', child: Text('mock')),
    ];
  }

  void _applyProfileDefaults() {
    // قم بضبط مزود وموديل افتراضيين حسب البروفايل المختار
    if (_isBudgetProfile) {
      _selectedProvider = 'openrouter';
      _selectedModel = 'qwen/qwen-2.5-vl-32b-instruct:free';
    } else {
      _selectedProvider = 'openrouter';
      _selectedModel = 'openai/gpt-4o';
    }
  }

  Future<void> _runPredictiveMaintenance() async {
    // Load or ask for vehicle
    var vehicle = await PredictiveMaintenanceService.loadVehicle();
    vehicle ??= await _askForVehicleProfile();
    if (vehicle == null) return;
    await PredictiveMaintenanceService.saveVehicle(vehicle);

    // Optionally add a quick sample log if none exists (demo)
    var logs = await PredictiveMaintenanceService.loadLogs();
    if (logs.isEmpty) {
      await PredictiveMaintenanceService.addLog(MaintenanceRecord(
        type: 'oil_change',
        date: DateTime.now().subtract(const Duration(days: 180)),
        odometerKm: (vehicle.mileageKm - 8000).clamp(0, vehicle.mileageKm),
        cost: 150,
        notes: 'تغيير زيت + فلتر (افتراضي للتجربة)'
      ));
      logs = await PredictiveMaintenanceService.loadLogs();
    }

    final tips = PredictiveMaintenanceService.computeReminders(vehicle, logs);
    final estimate = PredictiveMaintenanceService.estimateUpcomingCost(vehicle, logs);

    if (!mounted) return;
    setState(() {
      _conversation.add({
  'text': 'صيانة تنبؤية:\n- ${tips.join('\n- ')}\n\nتقدير تكلفة الصيانة القادمة: ~ $estimate ج.م',
        'isUser': false,
        'time': DateTime.now(),
      });
    });
  }

  Future<void> _runSmartRecommendations() async {
    final vehicle = await _askForVehicleProfile();
    if (vehicle == null) return;
    final recs = await SmartRecommendationService.recommend(vehicle);
    final text = recs.isEmpty
        ? 'لا توجد توصيات حالياً.'
        : recs.map((r) => '• ${r.title}').join('\n');
    if (!mounted) return;
    setState(() {
      _conversation.add({
        'text': 'توصيات ذكية:\n$text',
        'isUser': false,
        'time': DateTime.now(),
      });
    });
  }

  Future<VehicleProfile?> _askForVehicleProfile() async {
    final makeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final mileageCtrl = TextEditingController();
    String style = 'mixed';
    return showDialog<VehicleProfile>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('بيانات السيارة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: makeCtrl, decoration: const InputDecoration(labelText: 'الشركة (Make)')),
                TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'الموديل (Model)')),
                TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'سنة الصنع'), keyboardType: TextInputType.number),
                TextField(controller: mileageCtrl, decoration: const InputDecoration(labelText: 'العداد (كم)'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: style,
                  items: const [
                    DropdownMenuItem(value: 'city', child: Text('City (داخل المدن)')),
                    DropdownMenuItem(value: 'highway', child: Text('Highway (سفر)')),
                    DropdownMenuItem(value: 'mixed', child: Text('Mixed (مختلط)')),
                    DropdownMenuItem(value: 'aggressive', child: Text('Aggressive (قيادة عنيفة)')),
                  ],
                  onChanged: (v) => style = v ?? 'mixed',
                  decoration: const InputDecoration(labelText: 'أسلوب القيادة'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final year = int.tryParse(yearCtrl.text.trim()) ?? DateTime.now().year;
                final mileage = int.tryParse(mileageCtrl.text.trim()) ?? 0;
                final vp = VehicleProfile(
                  make: makeCtrl.text.trim(),
                  model: modelCtrl.text.trim(),
                  year: year,
                  mileageKm: mileage,
                  drivingStyle: style,
                );
                Navigator.pop(ctx, vp);
              },
              child: const Text('تأكيد'),
            )
          ],
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك أو اضغط الميكروفون...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  _processUserInput(text.trim());
                  _textController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic_off : Icons.mic,
              color: _isListening ? Colors.red : Colors.blue,
            ),
            onPressed: _isListening ? _stopListening : _startListening,
            tooltip: _isListening ? 'إيقاف التسجيل' : 'بدء التسجيل',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isUser = message['isUser'] as bool? ?? false;
    final String text = (message['text'] ?? '').toString();
    final Uint8List? imageBytes = message['imageBytes'] as Uint8List?;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              radius: 16,
              child: Icon(Icons.auto_awesome, size: 18),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[50] : Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isUser ? Colors.blue[100] : Colors.deepPurple[100])!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  if (imageBytes != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                        height: 220,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Icon(Icons.person, size: 18),
            ),
        ],
      ),
    );
  }

  Future<void> _generateImageFromPrompt() async {
    // حوار إدخال برومبت ونمط بسيط
    final promptCtrl = TextEditingController();
    String style = 'realistic';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('توليد صورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: promptCtrl,
              decoration: const InputDecoration(labelText: 'الوصف (برومبت)'),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: style,
              items: const [
                DropdownMenuItem(value: 'realistic', child: Text('واقعي')),
                DropdownMenuItem(value: '3d', child: Text('ثلاثي الأبعاد')),
                DropdownMenuItem(value: 'anime', child: Text('أنمي')),
                DropdownMenuItem(value: 'sketch', child: Text('رسم/سكتش')),
              ],
              onChanged: (v) => style = v ?? 'realistic',
              decoration: const InputDecoration(labelText: 'النمط'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('توليد')),
        ],
      ),
    );
    if (ok != true) return;
    final prompt = promptCtrl.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _conversation.add({
          'text': 'من فضلك اكتب وصفاً موجزاً للصورة.',
          'isUser': false,
          'time': DateTime.now(),
        });
      });
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // احترام الماستر سويتش
      final masterOn = await ApiRegistryService.isMasterEnabled();
      if (!masterOn) {
        if (!mounted) return;
        setState(() {
          _conversation.add({
            'text': 'الواجهات الخارجية معطلة حالياً من قبل الإدارة.',
            'isUser': false,
            'time': DateTime.now(),
          });
        });
        return;
      }

      // التوليد عبر الخادم (خدمة الوسائط تستخدم الوكيل أولاً)
      final bytes = await MediaAIService.generateImage(prompt, style: style);
      if (!mounted) return;
      if (bytes != null && bytes.isNotEmpty) {
        setState(() {
          _conversation.add({
            'text': 'تم توليد الصورة لهذا الوصف: "$prompt"',
            'imageBytes': bytes,
            'isUser': false,
            'time': DateTime.now(),
          });
        });
      } else {
        setState(() {
          _conversation.add({
            'text': 'تعذر توليد الصورة حالياً. جرّب وصفاً أبسط أو فعّل وضع المحاكاة على الخادم.',
            'isUser': false,
            'time': DateTime.now(),
          });
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _conversation.add({
          'text': 'حدث خطأ أثناء توليد الصورة: $e',
          'isUser': false,
          'time': DateTime.now(),
        });
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleImageInput() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (image == null) return;
      final Uint8List bytes = await image.readAsBytes();

      // استخدم الوكيل الخلفي لوصف الصورة وفق المزود المختار
      // احترم الماستر سويتش: إن كان معطلاً لا تنادي خدمات خارجية
      final masterOn = await ApiRegistryService.isMasterEnabled();
      if (!masterOn) {
        if (!mounted) return;
        setState(() {
          _conversation.add({
            'text': 'الواجهات الخارجية معطلة حالياً من قبل الإدارة.',
            'isUser': false,
            'time': DateTime.now(),
          });
        });
        return;
      }

      // تحقّق من تمكين المزود المختار من لوحة الإدارة
      if (_selectedProvider != 'mock') {
        final enabledProviders = await ApiRegistryService.getEnabled(category: 'vision');
        final keys = enabledProviders.map((e) => e.key).toSet();
        if (!keys.contains(_selectedProvider)) {
          if (!mounted) return;
          setState(() {
            _conversation.add({
              'text': 'المزوّد $_selectedProvider غير مفعّل حالياً من قبل الإدارة.',
              'isUser': false,
              'time': DateTime.now(),
            });
          });
          return;
        }
      }

      // استخدام خدمة تحليل قطع الغيار المتخصصة
      final result = await MediaAIService.analyzeCarPartImage(bytes);
      
      if (!mounted) return;
      
      // التحقق من وجود تحليل AI
      final aiAnalysis = result['ai_analysis'] as String?;
      final description = result['description'] as String?;
      final errorMsg = result['error'] as String?;
      
      if (aiAnalysis != null && aiAnalysis.isNotEmpty && !aiAnalysis.contains('تعذر')) {
        setState(() {
          _lastError = null;
          _conversation.add({
            'text': '🖼️ تحليل قطعة الغيار:\n\n$aiAnalysis',
            'isUser': false,
            'time': DateTime.now(),
          });
        });
      } else if (description != null && description.isNotEmpty) {
        setState(() {
          _lastError = errorMsg;
          _conversation.add({
            'text': '⚠️ $description',
            'isUser': false,
            'time': DateTime.now(),
          });
        });
      } else {
        setState(() {
          _lastError = errorMsg ?? 'تعذر تحليل الصورة';
          _conversation.add({
            'text': 'تعذر تحليل الصورة: ${errorMsg ?? 'خطأ غير معروف'}',
            'isUser': false,
            'time': DateTime.now(),
          });
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _conversation.add({
          'text': 'تعذر التقاط أو تحليل الصورة. ($e)',
          'isUser': false,
          'time': DateTime.now(),
        });
        _lastError = e.toString();
      });
    }
  }

  Future<void> _triggerDiagnosticFromPrompt() async {
    final text = _textController.text.trim().isNotEmpty
        ? _textController.text.trim()
        : _recognizedText.trim();
    if (text.isEmpty) {
      if (!mounted) return;
      setState(() {
        _conversation.add({
          'text': 'اكتب وصف العطل في مربع الكتابة ثم اضغط على أيقونة التشخيص.',
          'isUser': false,
          'time': DateTime.now(),
        });
      });
      return;
    }
    final dr = await DiagnosticService.diagnoseFromText(text);
    final causes = dr.probableCauses.map((e) => '• $e').join('\n');
    final parts = dr.suggestedParts.map((m) => '- ${m['name']} (${m['category'] ?? 'غير مصنّف'})').join('\n');
    if (!mounted) return;
    setState(() {
      _conversation.add({
        'text': '${dr.summary}\n\nأسباب محتملة:\n$causes\n\nقطع مقترحة من المخزون:\n${parts.isEmpty ? 'لا توجد اقتراحات حالياً' : parts}',
        'isUser': false,
        'time': DateTime.now(),
      });
    });
  }
}
