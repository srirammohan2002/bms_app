import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:intl/intl.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zbrkivjmdhvislshivqy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpicmtpdmptZGh2aXNsc2hpdnF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQyMTc0ODMsImV4cCI6MjA1OTc5MzQ4M30.Cd8Em8rLum0rtfycr2ZN_kBw6PXoBi_sRERTHYcK0yo',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMS Futuristic Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        cardTheme: CardTheme(
          elevation: 8,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.blueGrey.withOpacity(0.3), width: 1),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontFamily: 'Digital'),
          bodyLarge: TextStyle(color: Colors.white70),
        ),
      ),
      home: const CyberSplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CyberSplashScreen extends StatefulWidget {
  const CyberSplashScreen({super.key});

  @override
  _CyberSplashScreenState createState() => _CyberSplashScreenState();
}

class _CyberSplashScreenState extends State<CyberSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFF00E0FF),
      end: const Color(0xFFFF2D55),
    ).animate(_controller);

    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CyberMainScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _colorAnimation.value!.withOpacity(0.3),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.battery_charging_full,
                      size: 100,
                      color: _colorAnimation.value,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'BMS DIGITAL TWIN',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _colorAnimation.value,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: _colorAnimation.value!.withOpacity(0.8),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const CyberLoadingIndicator(),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CyberLoadingIndicator extends StatelessWidget {
  const CyberLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 2,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Positioned(
            left: 0,
            child: Container(
              width: 100,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00E0FF).withOpacity(0),
                    const Color(0xFF00E0FF),
                    const Color(0xFF00E0FF).withOpacity(0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class CyberMainScreen extends StatefulWidget {
  const CyberMainScreen({super.key});

  @override
  _CyberMainScreenState createState() => _CyberMainScreenState();
}

class _CyberMainScreenState extends State<CyberMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late RealtimeChannel _batteryTempChannel;
  double? _batteryTemp;
  double? _weatherTemp;
  String _weatherCondition = '';
  String _location = 'LOADING...';
  List<TemperatureData> _tempData = [];
  final String _weatherApiKey = '55134d3529aa4758a79162032250904';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _initRealtimeSubscription();
    _getWeatherData();
    _getHistoricalData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _batteryTempChannel.unsubscribe();
    super.dispose();
  }

  Future<void> _initRealtimeSubscription() async {
    final supabase = Supabase.instance.client;
    _batteryTempChannel = supabase
        .channel('battery_temp')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'battery_temperature',
          callback: (payload) {
            final newTemp = payload.newRecord['temperature'] as double;
            final timestamp =
                DateTime.parse(payload.newRecord['created_at'] as String);

            setState(() {
              _batteryTemp = newTemp;
              _tempData.add(
                TemperatureData(
                  timestamp: timestamp,
                  batteryTemp: newTemp,
                  weatherTemp: _weatherTemp,
                ),
              );

              if (_tempData.length > 50) _tempData.removeAt(0);
            });
          },
        )
        .subscribe();
  }

  Future<void> _getWeatherData() async {
    try {
      final position = await geo.Geolocator.getCurrentPosition();
      final response = await http.get(
        Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=$_weatherApiKey&q=${position.latitude},${position.longitude}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherTemp = data['current']['temp_c'];
          _weatherCondition = data['current']['condition']['text'];
          _location = data['location']['name'].toString().toUpperCase();

          for (var item in _tempData) {
            item.weatherTemp = _weatherTemp;
          }
        });
      }
    } catch (e) {
      print('Weather error: $e');
    }
  }

  Future<void> _getHistoricalData() async {
    final response = await Supabase.instance.client
        .from('battery_temperature')
        .select()
        .order('created_at', ascending: false)
        .limit(50);

    if (response != null) {
      setState(() {
        _tempData = response
            .map(
              (item) => TemperatureData(
                timestamp: DateTime.parse(item['created_at'] as String),
                batteryTemp: (item['temperature'] as num).toDouble(),
                weatherTemp: _weatherTemp,
              ),
            )
            .toList();
      });
    }
  }

  Widget _buildWeatherIcon() {
    final iconUrl = _weatherCondition.toLowerCase().contains('rain')
        ? 'https://cdn.weatherapi.com/weather/64x64/day/176.png'
        : 'https://cdn.weatherapi.com/weather/64x64/day/113.png';

    return Image.network(iconUrl, width: 60, height: 60);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('BMS FUTURISTIC DASHBOARD'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          indicatorColor: const Color(0xFF00E0FF),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.thermostat), text: 'DIGITAL TWIN'),
            Tab(icon: Icon(Icons.analytics), text: 'ANALYTICS'),
            Tab(icon: Icon(Icons.history), text: 'HISTORY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLiveDataTab(), _buildComparisonTab(), const HistoryScreen()],
      ),
    );
  }

  Widget _buildLiveDataTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFuturisticBatteryCard(),
          _buildCyberWeatherCard(),
        ],
      ),
    );
  }

  Widget _buildFuturisticBatteryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: const Color(0xFF111111),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EV BATTERY DIGITAL TWIN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00E0FF),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: FuturisticBatteryAnimation(
                temperature: _batteryTemp,
                width: 180,
                height: 300,
              ),
            ),
            const SizedBox(height: 20),
            _buildCyberStatsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCyberStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildStatRow('STATUS', _getBatteryStatus(), _getBatteryColor()),
          const Divider(color: Colors.blueGrey, height: 20),
          _buildStatRow('VOLTAGE', '46V', const Color(0xFF00FFA3)),
          const Divider(color: Colors.blueGrey, height: 20),
          _buildStatRow('CURRENT', '2.3A', const Color(0xFFFFD700)),
          const Divider(color: Colors.blueGrey, height: 20),
          _buildStatRow('HEALTH', '100%', const Color(0xFF00E0FF)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1.2,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getBatteryStatus() {
    if (_batteryTemp == null) return 'SCANNING';
    if (_batteryTemp! < 20) return 'OPTIMAL';
    if (_batteryTemp! < 40) return 'NOMINAL';
    if (_batteryTemp! < 50) return 'WARNING';
    return 'CRITICAL';
  }

  Color _getBatteryColor() {
    if (_batteryTemp == null) return Colors.blueGrey;
    if (_batteryTemp! < 20) return const Color(0xFF00E0FF);
    if (_batteryTemp! < 40) return const Color(0xFF00FFA3);
    if (_batteryTemp! < 50) return const Color(0xFFFFD700);
    return const Color(0xFFFF2D55);
  }

  Widget _buildCyberWeatherCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ENVIRONMENT MONITOR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00E0FF),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildWeatherIcon(),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _location,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weatherCondition.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Text(
                      _weatherTemp != null
                          ? '${_weatherTemp!.toStringAsFixed(1)}°C'
                          : '--.-°C',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00E0FF).withOpacity(
                          0.7 + _pulseController.value * 0.3,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'TEMPERATURE ANALYSIS',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00E0FF),
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              backgroundColor: Colors.transparent,
              primaryXAxis: DateTimeAxis(
                title: AxisTitle(
                  text: 'TIME',
                  textStyle: const TextStyle(color: Colors.white70),
                ),
                dateFormat: DateFormat.Hm(),
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: const TextStyle(color: Colors.white70),
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(
                  text: 'TEMP (°C)',
                  textStyle: const TextStyle(color: Colors.white70),
                ),
                axisLine: const AxisLine(width: 0),
                majorGridLines: MajorGridLines(
                  color: Colors.blueGrey.withOpacity(0.3),
                ),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: const TextStyle(color: Colors.white70),
              ),
              legend: Legend(
                isVisible: true,
                position: LegendPosition.top,
                textStyle: const TextStyle(color: Colors.white),
              ),
              series: <CartesianSeries>[
                LineSeries<TemperatureData, DateTime>(
                  dataSource: _tempData,
                  xValueMapper: (data, _) => data.timestamp,
                  yValueMapper: (data, _) => data.batteryTemp,
                  name: 'BATTERY',
                  color: const Color(0xFF00E0FF),
                  width: 3,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    shape: DataMarkerType.diamond,
                    borderWidth: 2,
                    borderColor: Color(0xFF00E0FF),
                  ),
                ),
                LineSeries<TemperatureData, DateTime>(
                  dataSource: _tempData,
                  xValueMapper: (data, _) => data.timestamp,
                  yValueMapper: (data, _) => data.weatherTemp,
                  name: 'AMBIENT',
                  color: const Color(0xFFFFD700),
                  width: 3,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    shape: DataMarkerType.circle,
                    borderWidth: 2,
                    borderColor: Color(0xFFFFD700),
                  ),
                ),
              ],
              tooltipBehavior: TooltipBehavior(
                enable: true,
                format: 'point.x : point.y°C',
                textStyle: const TextStyle(color: Colors.white),
                color: Colors.black,
                borderColor: const Color(0xFF00E0FF),
              ),
            ),
          ),
          _buildCyberTempDifferenceCard(),
        ],
      ),
    );
  }

  Widget _buildCyberTempDifferenceCard() {
    if (_batteryTemp == null || _weatherTemp == null) {
      return const SizedBox();
    }

    final diff = (_batteryTemp! - _weatherTemp!).abs();
    final isWarmer = _batteryTemp! > _weatherTemp!;
    final diffColor =
        isWarmer ? const Color(0xFFFF2D55) : const Color(0xFF00E0FF);

    return Card(
      color: Colors.black,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isWarmer ? Icons.arrow_upward : Icons.arrow_downward,
              color: diffColor,
              size: 30,
            ),
            const SizedBox(width: 12),
            Text(
              'DELTA: ${diff.toStringAsFixed(1)}°C ',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              isWarmer ? 'ABOVE AMBIENT' : 'BELOW AMBIENT',
              style: TextStyle(
                fontSize: 16,
                color: diffColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _historyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    try {
      final response = await Supabase.instance.client
          .from('battery_temperature')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      if (response != null) {
        setState(() {
          _historyData = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('TEMPERATURE HISTORY'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoryData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: SpinKitFadingCube(
                color: Color(0xFF00E0FF),
                size: 50.0,
              ),
            )
          : _buildHistoryList(),
    );
  }

  Widget _buildHistoryList() {
    if (_historyData.isEmpty) {
      return Center(
        child: Text(
          'No history data available',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 18,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyData.length,
      itemBuilder: (context, index) {
        final item = _historyData[index];
        final temp = item['temperature'] as num;
        final timestamp = DateTime.parse(item['created_at'] as String);
        final formattedDate = DateFormat('MMM dd, yyyy').format(timestamp);
        final formattedTime = DateFormat('HH:mm:ss').format(timestamp);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.black,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildTemperatureIndicator(temp.toDouble()),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$formattedDate at $formattedTime',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${temp.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getTempColor(temp.toDouble()),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.blueGrey.withOpacity(0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemperatureIndicator(double temp) {
    final color = _getTempColor(temp);
    final size = 50.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          temp.toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getTempColor(double temp) {
    if (temp < 20) return const Color(0xFF00E0FF);
    if (temp < 40) return const Color(0xFF00FFA3);
    if (temp < 50) return const Color(0xFFFFD700);
    return const Color(0xFFFF2D55);
  }
}

class FuturisticBatteryAnimation extends StatelessWidget {
  final double? temperature;
  final double width;
  final double height;

  const FuturisticBatteryAnimation({
    super.key,
    required this.temperature,
    this.width = 150,
    this.height = 250,
  });

  Color _getBatteryColor() {
    if (temperature == null) return Colors.blueGrey;
    if (temperature! < 20) return const Color(0xFF00E0FF);
    if (temperature! < 40) return const Color(0xFF00FFA3);
    if (temperature! < 50) return const Color(0xFFFFD700);
    return const Color(0xFFFF2D55);
  }

  double _getFillPercentage() {
    if (temperature == null) return 0.1;
    return (temperature! / 60).clamp(0.05, 0.95);
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = _getBatteryColor();
    final fillPercentage = _getFillPercentage();
    final fillHeight = (height - 20) * fillPercentage;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: fillColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF111111),
                  Color(0xFF0A0A0A),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: CustomPaint(
                      painter: _GridPainter(),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(
                          height: fillHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                fillColor.withOpacity(0.8),
                                fillColor.withOpacity(0.4),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.6,
                            child: CustomPaint(
                              painter: _LiquidWavePainter(
                                fillPercentage: fillPercentage,
                                waveColor: fillColor,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: width * 0.3,
                  right: width * 0.3,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                      border: Border.all(
                        color: Colors.grey[600]!,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: height * 0.4,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        temperature != null
                            ? '${temperature!.toStringAsFixed(1)}°C'
                            : '--.-°C',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: fillColor,
                          shadows: [
                            Shadow(
                              color: fillColor.withOpacity(0.8),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: width * 0.6,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: width * 0.6 * fillPercentage,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    fillColor,
                                    fillColor.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: _buildHUDItem('VOLT', '46V'),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: _buildHUDItem('AMP', '2.3A'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUDItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (temperature == null) return 'SCANNING...';
    if (temperature! < 20) return 'OPTIMAL';
    if (temperature! < 40) return 'NOMINAL';
    if (temperature! < 50) return 'WARNING';
    return 'CRITICAL!';
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += 15) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LiquidWavePainter extends CustomPainter {
  final double fillPercentage;
  final Color waveColor;

  _LiquidWavePainter({
    required this.fillPercentage,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    final amplitude = size.height * 0.05;
    final frequency = 0.5;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * (1 - fillPercentage) +
          amplitude * sin(now * 2 + x * frequency * 0.1);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    final paint = Paint()
      ..color = waveColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) =>
      oldDelegate.fillPercentage != fillPercentage;
}

class TemperatureData {
  DateTime timestamp;
  double? batteryTemp;
  double? weatherTemp;

  TemperatureData({
    required this.timestamp,
    required this.batteryTemp,
    required this.weatherTemp,
  });
}
