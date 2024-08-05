import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flapod',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String apodUrl = '';
  String apodTitle = '';
  String apodDescription = '';
  bool isVideo = false;

  @override
  void initState() {
    super.initState();
    fetchAPOD();
  }

  Future<void> fetchAPOD() async {
    final response = await http.get(Uri.parse(
        'https://api.nasa.gov/planetary/apod?api_key=Vy7VIaEuCnDhsMTeVPRe9MJZgGuBfD73P7SMXLb2'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        apodUrl = data['url'];
        apodTitle = data['title'];
        apodDescription = data['explanation'];
        isVideo = data['media_type'] == 'video';
      });
    } else {
      throw Exception('Failed to load APOD');
    }
  }

  Future<void> _launchURL() async {
    if (await canLaunch(apodUrl)) {
      await launch(apodUrl);
    } else {
      throw 'Could not launch $apodUrl';
    }
  }

  Future<void> showFAQDialog(BuildContext context) async {
    final faqContent = await rootBundle.loadString('assets/FAQ.txt');
    final faqLines = faqContent.split('\n');
    final faqList = faqLines.length.isOdd
        ? faqLines.sublist(0, faqLines.length - 1)
        : faqLines;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('FAQ'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: faqList.asMap().entries.map((entry) {
                if (entry.key % 2 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      entry.value,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(entry.value),
                  );
                }
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flapod'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () => showFAQDialog(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              apodTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            isVideo
                ? Text(
                    'Video available, click the View on NASA APOD button',
                    textAlign: TextAlign.center,
                  )
                : Image.network(apodUrl),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(apodDescription, textAlign: TextAlign.center),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _launchURL,
              child: Text('View on NASA APOD'),
            ),
          ],
        ),
      ),
    );
  }
}
