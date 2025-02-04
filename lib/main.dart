import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.blueGrey[50],
        textTheme: TextTheme(
          bodyMedium: TextStyle(
              color: const Color.fromARGB(255, 47, 53, 67),
              fontFamily: 'Archive'),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromARGB(255, 47, 53, 67),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Archive'),
        ),
      ),
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String city = "Loading...";
  String country = "Loading...";
  String temperature = "Loading...";
  String weatherCondition = "";
  IconData weatherIcon = Icons.wb_sunny;
  double latitude = 0;
  double longitude = 0;

  @override
  void initState() {
    super.initState();
    _getLocationAndWeather();
  }

  Future<void> _getLocationAndWeather() async {
    Position position = await _determinePosition();
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
    await fetchWeather(latitude, longitude);
  }

  Future<void> fetchWeather(double latitude, double longitude) async {
    String apiKey = "6252f0f2fa0ac02dae50d66fd16be8f3";
    String url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          temperature = "${data['main']['temp'].toString()}°C";
          weatherCondition = data['weather'][0]['description'];
          weatherIcon = _getWeatherIcon(data['weather'][0]['main']);
          city = data['name'];
          country = data['sys']['country'];
        });
      } else {
        setState(() {
          temperature = "Error loading data";
        });
      }
    } catch (e) {
      setState(() {
        temperature = "Error fetching data";
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'smoke':
        return Icons.foggy;
      default:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var isDarkMode = theme.brightness == Brightness.dark;
    var commonTextColor =
        isDarkMode ? Colors.white : const Color.fromRGBO(47, 53, 67, 1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$city, $country',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: commonTextColor,
              ),
            ),
            SizedBox(height: 150),
            Icon(
              weatherIcon,
              size: 100,
              color: commonTextColor,
            ),
            SizedBox(height: 10),
            Text(
              temperature,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: commonTextColor,
              ),
            ),
            Text(
              weatherCondition,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: commonTextColor),
            ),
            SizedBox(height: 40),
            ForecastWidget(latitude: latitude, longitude: longitude),
          ],
        ),
      ),
    );
  }
}

class ForecastWidget extends StatelessWidget {
  final double latitude;
  final double longitude;

  const ForecastWidget({Key? key, required this.latitude, required this.longitude})
      : super(key: key);

  Future<List<Map<String, dynamic>>> fetchForecast(
      double latitude, double longitude) async {
    String apiKey = "6252f0f2fa0ac02dae50d66fd16be8f3";
    String url =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> forecast = [];
        String currentDay =
            DateFormat('dd-MM-yyyy').format(DateTime.now());

        for (var item in data['list']) {
          String day = DateFormat('dd-MM-yyyy').format(
              DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000));

          if (day != currentDay &&
              !forecast.any((f) => f['date'] == day)) {
            forecast.add({
              'date': day,
              'day': DateFormat('E').format(
                  DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000)),
              'maxTemp': item['main']['temp_max'].round().toString() + '°',
              'minTemp': item['main']['temp_min'].round().toString() + '°',
              'icon': _getWeatherIcon(item['weather'][0]['main']),
            });
          }
          if (forecast.length == 4) break;
        }
        return forecast;
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      throw Exception('Failed to fetch forecast: $e');
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'smoke':
        return Icons.foggy;
      default:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return FutureBuilder(
      future: fetchForecast(latitude, longitude),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Column(
            children: [
              Text(
                "Error loading forecast",
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
              ElevatedButton(
                onPressed: () => {},
                child: Text("Retry"),
              ),
            ],
          );
        }
        List<Map<String, dynamic>> forecast =
            snapshot.data as List<Map<String, dynamic>>;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: forecast.map((day) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day['day'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(
                      DateFormat('dd-MM-yyyy').parse(day['date'])),
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
                Icon(
                  day['icon'],
                  size: 30,
                  color: theme.textTheme.bodyMedium?.color,
                ),
                Text(
                  day['maxTemp'],
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color),
                ),
                Text(
                  day['minTemp'],
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
