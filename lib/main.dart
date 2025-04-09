import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:intl/intl.dart';

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
      title: 'BMS Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: const CardTheme(
          elevation: 4,
          margin: EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuint,
    );
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
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
      backgroundColor: Colors.blue[800],
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 180, height: 180),
              const SizedBox(height: 20),
              Text(
                'Battery Monitoring System',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 30),
              const SpinKitFadingCircle(color: Colors.white, size: 40.0),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // ignore: unused_field
  late RealtimeChannel _batteryTempChannel;
  double? _batteryTemp;
  double? _weatherTemp;
  String _weatherCondition = '';
  String _location = 'Loading...';
  List<TemperatureData> _tempData = [];
  final String _weatherApiKey = '55134d3529aa4758a79162032250904';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initRealtimeSubscription();
    _getWeatherData();
    _getHistoricalData();
  }

  Future<void> _initRealtimeSubscription() async {
    final supabase = Supabase.instance.client;
    _batteryTempChannel =
        supabase
            .channel('battery_temp')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'battery_temperature',
              callback: (payload) {
                final newTemp = payload.newRecord['temperature'] as double;
                final timestamp = DateTime.parse(
                  payload.newRecord['created_at'] as String,
                );

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
          _location = data['location']['name'];

          // Update weather temp in historical data
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

    // ignore: unnecessary_null_comparison
    if (response != null) {
      setState(() {
        _tempData =
            response
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
    final iconUrl =
        _weatherCondition.toLowerCase().contains('rain')
            ? 'https://cdn.weatherapi.com/weather/64x64/day/176.png'
            : 'https://cdn.weatherapi.com/weather/64x64/day/113.png';

    return Image.network(iconUrl, width: 60, height: 60);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMS Dashboard'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.thermostat), text: 'Live Data'),
            Tab(icon: Icon(Icons.analytics), text: 'Comparison'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLiveDataTab(), _buildComparisonTab()],
      ),
    );
  }

  Widget _buildLiveDataTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatusCard(
            title: 'Battery Status',
            value: _batteryTemp,
            unit: '°C',
            icon: Icons.battery_full,
            statusColor: _getTempColor(_batteryTemp),
          ),
          _buildWeatherCard(),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Temperature Comparison',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                title: AxisTitle(text: 'Time'),
                dateFormat: DateFormat.Hm(),
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(text: 'Temperature (°C)'),
              ),
              legend: Legend(isVisible: true, position: LegendPosition.top),
              series: <CartesianSeries>[
                LineSeries<TemperatureData, DateTime>(
                  dataSource: _tempData,
                  xValueMapper: (data, _) => data.timestamp,
                  yValueMapper: (data, _) => data.batteryTemp,
                  name: 'Battery',
                  color: Colors.blue[700],
                  markerSettings: const MarkerSettings(isVisible: true),
                ),
                LineSeries<TemperatureData, DateTime>(
                  dataSource: _tempData,
                  xValueMapper: (data, _) => data.timestamp,
                  yValueMapper: (data, _) => data.weatherTemp,
                  name: 'Ambient',
                  color: Colors.orange[400],
                  markerSettings: const MarkerSettings(isVisible: true),
                ),
              ],
              tooltipBehavior: TooltipBehavior(
                enable: true,
                format: 'point.x : point.y°C',
              ),
            ),
          ),
          _buildTempDifferenceCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required double? value,
    required String unit,
    required IconData icon,
    required Color statusColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value != null ? '${value.toStringAsFixed(1)}$unit' : '--',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 8,
              width: 100,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value != null ? (value / 60).clamp(0.0, 1.0) : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weather Conditions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weatherCondition,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _weatherTemp != null
                      ? '${_weatherTemp!.toStringAsFixed(1)}°C'
                      : '--',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempDifferenceCard() {
    if (_batteryTemp == null || _weatherTemp == null) {
      return const SizedBox();
    }

    final diff = (_batteryTemp! - _weatherTemp!).abs();
    final isWarmer = _batteryTemp! > _weatherTemp!;

    return Card(
      color: isWarmer ? Colors.orange[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isWarmer ? Icons.arrow_upward : Icons.arrow_downward,
              color: isWarmer ? Colors.orange : Colors.blue,
              size: 30,
            ),
            const SizedBox(width: 12),
            Text(
              'Battery is ${diff.toStringAsFixed(1)}°C '
              '${isWarmer ? 'warmer' : 'cooler'} than ambient',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTempColor(double? temp) {
    if (temp == null) return Colors.grey;
    if (temp < 20) return Colors.blue;
    if (temp < 40) return Colors.green;
    if (temp < 50) return Colors.orange;
    return Colors.red;
  }
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
