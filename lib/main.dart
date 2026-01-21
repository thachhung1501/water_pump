import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

void main() {
  runApp(const SmartWaterPumpApp());
}

// --- MODEL DỮ LIỆU ---
class ESPData {
  final double humidity;
  final bool pumpOn;
  final bool autoMode;
  final double threshold;

  ESPData({
    required this.humidity,
    required this.pumpOn,
    required this.autoMode,
    required this.threshold,
  });

  factory ESPData.fromJson(Map<String, dynamic> json) {
    return ESPData(
      humidity: (json['humidity'] ?? 0).toDouble(),
      pumpOn: json['pumpOn'] ?? false,
      autoMode: json['autoMode'] ?? true,
      threshold: (json['threshold'] ?? 40).toDouble(),
    );
  }
}

class SmartWaterPumpApp extends StatelessWidget {
  const SmartWaterPumpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Water Pump',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const WaterPumpControlPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WaterPumpControlPage extends StatefulWidget {
  const WaterPumpControlPage({super.key});

  @override
  State<WaterPumpControlPage> createState() => _WaterPumpControlPageState();
}

class _WaterPumpControlPageState extends State<WaterPumpControlPage> {
  // --- CẤU HÌNH ---
  String _ipAddress = "192.168.1.100";
  
  // Trạng thái dữ liệu
  double _humidity = 0;
  double _threshold = 40;
  bool _pumpOn = false;
  bool _autoMode = true;
  
  // Trạng thái kết nối
  bool _isConnected = false;
  bool _isChecking = false;
  
  // Timer tự động cập nhật
  Timer? _timer;
  
  // Controllers
  late TextEditingController _ipController;
  late FocusNode _ipFocusNode;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: _ipAddress);
    _ipFocusNode = FocusNode();
    _loadSavedIP();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ipController.dispose();
    _ipFocusNode.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _fetchDataFromESP();
      }
    });
    // Fetch ngay lần đầu
    _fetchDataFromESP();
  }

  // Load IP đã lưu từ SharedPreferences
  Future<void> _loadSavedIP() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIP = prefs.getString('saved_ip') ?? "192.168.1.100";
    setState(() {
      _ipAddress = savedIP;
      _ipController.text = savedIP;
    });
  }

  // Lưu IP vào SharedPreferences
  Future<void> _saveIP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_ip', _ipAddress);
  }

  // Lấy dữ liệu từ ESP32
  Future<void> _fetchDataFromESP() async {
    final urlString = "http://$_ipAddress/status";
    
    if (!mounted) return;
    
    setState(() {
      _isChecking = true;
    });

    try {
      final response = await http.get(
        Uri.parse(urlString),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 2));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final espData = ESPData.fromJson(data);
        
        setState(() {
          _isConnected = true;
          _humidity = espData.humidity;
          if (_autoMode) {
            _pumpOn = espData.pumpOn;
          }
          _isChecking = false;
        });
      } else {
        _setDisconnected();
      }
    } catch (e) {
      if (mounted) {
        _setDisconnected();
      }
    }
  }

  void _setDisconnected() {
    setState(() {
      _isConnected = false;
      _isChecking = false;
    });
  }

  // Gửi lệnh điều khiển
  Future<void> _sendControlToESP() async {
    if (!_isConnected) return;

    final urlString = "http://$_ipAddress/set?auto=$_autoMode&threshold=${_threshold.toInt()}&pump=$_pumpOn";
    
    try {
      await http.get(Uri.parse(urlString)).timeout(const Duration(seconds: 2));
    } catch (e) {
      // Có thể hiện thông báo lỗi nếu cần
    }
  }

  void _hideKeyboard() {
    _ipFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.2),
              Colors.green.withOpacity(0.2),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: _hideKeyboard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Tiêu đề
                Text(
                  'Smart Water Pump',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Phần nhập IP
                _buildIPInputSection(),
                
                const SizedBox(height: 30),
                
                // Vòng tròn độ ẩm
                _buildHumidityCircle(),
                
                const SizedBox(height: 30),
                
                // Trạng thái máy bơm
                _buildPumpStatus(),
                
                const SizedBox(height: 30),
                
                // Bảng điều khiển
                _buildControlPanel(),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIPInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'IP:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _ipController,
                  focusNode: _ipFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Ex: 192.168.1.100',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (value) {
                    _ipAddress = value;
                    _saveIP();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _hideKeyboard();
                  _fetchDataFromESP();
                },
                icon: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isConnected ? 'Connected to ESP32' : 'Connection Lost / Invalid IP',
                style: TextStyle(
                  fontSize: 12,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityCircle() {
    return Container(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: 1.0,
                color: Colors.blue.withOpacity(0.2),
                strokeWidth: 18,
              ),
            ),
          ),
          // Progress circle
          Container(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: _humidity / 100,
                color: _isConnected ? Colors.blue : Colors.grey,
                strokeWidth: 18,
                useGradient: _isConnected,
              ),
            ),
          ),
          // Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.water_drop,
                size: 36,
                color: _isConnected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                _isConnected ? '${_humidity.toInt()}%' : '--',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _isConnected ? Colors.black87 : Colors.grey,
                ),
              ),
              Text(
                'Humidity',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPumpStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: (_pumpOn && _isConnected) ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: (_pumpOn && _isConnected)
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.7),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            _pumpOn ? Icons.settings : Icons.settings_outlined,
            color: (_pumpOn && _isConnected) ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            _pumpOn ? 'Pump Running' : 'Pump Stopped',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: (_pumpOn && _isConnected) ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Auto mode toggle
          SwitchListTile(
            title: const Text('Automatic Mode'),
            value: _autoMode,
            onChanged: _isConnected
                ? (bool value) {
                    setState(() {
                      _autoMode = value;
                    });
                    _sendControlToESP();
                  }
                : null,
          ),
          
          const SizedBox(height: 20),
          
          // Threshold slider
          Text(
            'Threshold: ${_threshold.toInt()}%',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          
          Slider(
            value: _threshold,
            min: 20,
            max: 80,
            divisions: 60,
            onChanged: _isConnected
                ? (double value) {
                    setState(() {
                      _threshold = value;
                    });
                    _sendControlToESP();
                  }
                : null,
          ),
          
          const SizedBox(height: 20),
          
          // Manual control button (when auto mode is off)
          if (!_autoMode)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnected
                    ? () {
                        setState(() {
                          _pumpOn = !_pumpOn;
                        });
                        _sendControlToESP();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pumpOn ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _pumpOn ? 'STOP PUMP' : 'START PUMP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool useGradient;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 10.0,
    this.useGradient = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    if (useGradient && progress > 0) {
      final sweepGradient = SweepGradient(
        colors: [
          Colors.blue,
          Colors.cyan,
          Colors.green,
        ],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * progress),
      );
      
      paint.shader = sweepGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    } else {
      paint.color = color;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
