import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../helpers/session.dart';
import 'package:intl/intl.dart'; // Untuk format waktu
import 'package:awesome_notifications/awesome_notifications.dart';


class DetailCartPage extends StatefulWidget {
  final int animeId;

  const DetailCartPage({Key? key, required this.animeId}) : super(key: key);

  @override
  _DetailCartPageState createState() => _DetailCartPageState();
}

class _DetailCartPageState extends State<DetailCartPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic>? _animeData;
  String? _watchTime;
  String _selectedTimezone = 'WIB'; // Default timezone
  String _selectedCurrency = 'Rupiah'; // Default currency
  double _currencyRate = 1.0; // Conversion rate
  int _pricePerEpisode = 5000; // Default price per episode
  double? _totalCost; // Total cost calculation
  String _reminderTime = 'Now'; // Default reminder time

  // Map Timezone Offset
  final Map<String, int> _timezoneOffsets = {
    'WIB': 0,
    'WITA': 1,
    'WIT': 2,
    'London': -7,
    'Tokyo': 9,
    'New York': -12,
  };

  // Map Currency Conversion Rates (relative to Rupiah)
  final Map<String, double> _currencyRates = {
    'Rupiah': 1.0,
    'RMB': 0.00066,
    'Yen': 0.0073,
    'Won': 0.085,
    'Dollar US': 0.000065,
    'Pound': 0.000054,
  };

  @override
  void initState() {
    super.initState();
    _fetchAnimeDetails();
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'anime_reminder',
          channelName: 'Anime Reminders',
          channelDescription: 'Notification for Anime Reminder',
          defaultColor: Colors.blue,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        )
      ],
    );
    _requestNotificationPermission();
  }
  Future<void> _requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // Tampilkan dialog meminta izin
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> _fetchAnimeDetails() async {
    final userId = Session.currentUserId;
    if (userId == null) {
      setState(() {
        _animeData = null;
      });
      return;
    }

    final anime = await _dbHelper.getAnimeById(userId, widget.animeId);
    setState(() {
      _animeData = anime;
    });
  }

  void _calculateTotalCost() {
    final episodes = _animeData?['episodes'] ?? 0;
    setState(() {
      _totalCost = episodes * _pricePerEpisode * _currencyRate;
    });
  }

  void _calculateWatchTime() {
    if (_animeData == null) return;

    final totalMinutes = (_animeData!['episodes'] ?? 0) *
        (_animeData!['duration_minutes'] ?? 0);

    if (totalMinutes > 0) {
      final now = DateTime.now();
      final futureTime = now.add(Duration(minutes: totalMinutes));

      // Adjust for timezone
      final offsetHours = _timezoneOffsets[_selectedTimezone] ?? 0;
      final adjustedTime = futureTime.add(Duration(hours: offsetHours));

      setState(() {
        _watchTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(adjustedTime);
      });
    } else {
      setState(() {
        _watchTime = 'Invalid data for watch time';
      });
    }
  }

  int? _calculateTotalViewingTime() {
    if (_animeData == null) return null;
    final episodes = _animeData?['episodes'] ?? 0;
    final averageTime = _animeData?['duration_minutes'] ?? 0;
    return episodes * averageTime;
  }
  Future<void> _scheduleNotification() async {
    // Periksa apakah notifikasi diizinkan
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // Jika tidak diizinkan, minta izin dari pengguna
      await AwesomeNotifications().requestPermissionToSendNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enable notifications for this app.')),
      );
      return;
    }

    // Periksa apakah data anime tersedia
    if (_animeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anime data is not available!')),
      );
      return;
    }

    // Ambil detail anime
    final animeTitle = _animeData!['title'] ?? 'Unknown Anime';
    final animeImageUrl = _animeData!['image_url'] ?? '';

    // Tentukan waktu delay berdasarkan pilihan pengguna
    Duration delay = Duration.zero;

    switch (_reminderTime) {
      case 'Now':
        delay = Duration(seconds: 5); // Set minimum jeda 5 detik
        break;
      case '1 minute':
        delay = Duration(seconds: 60);
        break;
      case '1 hour':
        delay = Duration(hours: 1);
        break;
      case '1 day':
        delay = Duration(days: 1);
        break;
    }


    // Hitung waktu penjadwalan
    final scheduleTime = DateTime.now().add(delay);
    print('Notifikasi dijadwalkan pada: $scheduleTime');

    // Validasi apakah waktu penjadwalan valid
    if (scheduleTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid schedule time! Please select a future time.')),
      );
      return;
    }

    // Buat notifikasi terjadwal menggunakan AwesomeNotifications
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000), // ID unik untuk notifikasi
        channelKey: 'anime_reminder',
        title: 'Jangan lupa nonton $animeTitle',
        body: 'Anime favoritmu menunggu!',
        bigPicture: animeImageUrl,
        notificationLayout: NotificationLayout.BigPicture, // Menampilkan gambar besar
      ),
      schedule: NotificationCalendar(
        year: scheduleTime.year,
        month: scheduleTime.month,
        day: scheduleTime.day,
        hour: scheduleTime.hour,
        minute: scheduleTime.minute,
        second: scheduleTime.second,
        preciseAlarm: true, // Pastikan alarm tepat waktu
      ),
    );

    // Tampilkan notifikasi bahwa pengingat berhasil diatur
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Reminder set for $animeTitle'),
    ));
  }


  @override
  Widget build(BuildContext context) {
    final totalViewingTime = _calculateTotalViewingTime();
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Anime'),
      ),
      body: _animeData == null
          ? Center(child: Text('Anime not found or no data available'))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Anime
              if (_animeData!['image_url'] != null)
                Image.network(
                  _animeData!['image_url'],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey,
                      child: Center(
                        child: Text(
                          'Image not available',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              SizedBox(height: 16),

              // Judul Anime
              Text(
                _animeData!['title'] ?? 'No Title',
                style:
                TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // Informasi Episode
              Text(
                'Episodes: ${_animeData!['episodes'] ?? "Unknown"}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),

              // Average Time per Episode
              if (_animeData!['duration_minutes'] != null)
                Text(
                  'Average Time per Episode: ${_animeData!['duration_minutes']} minutes',
                  style: TextStyle(fontSize: 16),
                ),
              SizedBox(height: 16),

              // Total Viewing Time
              if (totalViewingTime != null)
                Text(
                  'Total Viewing Time: $totalViewingTime minutes',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[800], // Latar belakang abu-abu tua
                  borderRadius: BorderRadius.circular(8), // Sudut melingkar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remind Me Later',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Teks putih
                      ),
                    ),
                    SizedBox(height: 8), // Jarak antara teks dan konten
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _scheduleNotification,
                          icon: Icon(Icons.notifications),
                          label: Text('Remind Me Later'),
                        ),
                        DropdownButton<String>(
                          value: _reminderTime,
                          dropdownColor: Colors.grey[850], // Latar dropdown abu-abu tua
                          onChanged: (String? newValue) {
                            setState(() {
                              _reminderTime = newValue!;
                            });
                          },
                          items: <String>[
                            'Now',
                            '1 minute',
                            '1 hour',
                            '1 day'
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(color: Colors.white), // Teks dropdown putih
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Teks "Payment"
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[800], // Latar belakang abu-abu tua
                  borderRadius: BorderRadius.circular(8), // Sudut melingkar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul Payment
                    Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Teks putih
                      ),
                    ),
                    SizedBox(height: 8),

                    // Input Price per Episode
                    Row(
                      children: [
                        Text(
                          'Price per Episode:',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _pricePerEpisode = int.tryParse(value) ?? 5000;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter price',
                              hintStyle: TextStyle(color: Colors.grey[400]), // Warna hint
                              filled: true,
                              fillColor: Colors.grey[700], // Latar belakang input
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(color: Colors.white), // Teks putih
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Pilihan Mata Uang
                    Row(
                      children: [
                        Text(
                          'Currency:',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedCurrency,
                          dropdownColor: Colors.grey[850], // Latar dropdown abu-abu tua
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCurrency = newValue!;
                              _currencyRate = _currencyRates[_selectedCurrency]!;
                            });
                          },
                          items: _currencyRates.keys.map<DropdownMenuItem<String>>((String currency) {
                            return DropdownMenuItem<String>(
                              value: currency,
                              child: Text(
                                currency,
                                style: TextStyle(color: Colors.white), // Teks putih
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    // Tombol untuk Menghitung Total Biaya
                    ElevatedButton(
                      onPressed: _calculateTotalCost,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.grey[850], // Warna teks tombol
                      ),
                      child: Text('Pay'),
                    ),

                    // Total Cost
                    if (_totalCost != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Total Cost: ${_totalCost!.toStringAsFixed(2)} $_selectedCurrency',
                          style: TextStyle(fontSize: 16, color: Colors.lightBlue),
                        ),
                      ),

                    // Estimated Time
                    SizedBox(height: 16),
                    Text(
                      'Estimated Time',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Teks putih
                      ),
                    ),
                    SizedBox(height: 8),

                    // Dropdown Timezone
                    Row(
                      children: [
                        Text(
                          'Timezone:',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedTimezone,
                          dropdownColor: Colors.grey[850], // Latar dropdown abu-abu tua
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTimezone = newValue!;
                            });
                          },
                          items: _timezoneOffsets.keys.map<DropdownMenuItem<String>>((String timezone) {
                            return DropdownMenuItem<String>(
                              value: timezone,
                              child: Text(
                                timezone,
                                style: TextStyle(color: Colors.white), // Teks putih
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Tombol Watch
                    ElevatedButton(
                      onPressed: _calculateWatchTime,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.grey[850], // Warna teks tombol
                      ),
                      child: Text('Watch'),
                    ),

                    // Estimated End Time
                    if (_watchTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Estimated End Time ($_selectedTimezone): $_watchTime',
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                      ),
                  ],
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}
