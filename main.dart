import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const Flapod());
}

class Flapod extends StatelessWidget {
  const Flapod({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flapod',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ApodPage(),
    );
  }
}

class ApodPage extends StatefulWidget {
  const ApodPage({Key? key}) : super(key: key);

  @override
  _ApodPageState createState() => _ApodPageState();
}

class _ApodPageState extends State<ApodPage> {
  final String apiKey = 'Vy7VIaEuCnDhsMTeVPRe9MJZgGuBfD73P7SMXLb2';
  late Future<Map<String, dynamic>> _apodData;

  @override
  void initState() {
    super.initState();
    _apodData = fetchApodData();
  }

  Future<Map<String, dynamic>> fetchApodData() async {
    final response = await http.get(Uri.parse(
        'https://api.nasa.gov/planetary/apod?api_key=$apiKey'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load APOD');
    }
  }

  Future<List<String>> loadFaq() async {
    final faqData = await DefaultAssetBundle.of(context).loadString('assets/FAQ.txt');
    return faqData.split('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flapod'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () async {
              final faq = await loadFaq();
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('FAQ'),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: faq.asMap().entries.where((entry) => entry.key % 2 == 0).map((entry) {
                          int index = entry.key;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Q: ${faq[index]}'),
                              if (index + 1 < faq.length) Text('A: ${faq[index + 1]}'),
                              const SizedBox(height: 10),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _apodData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load image today',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            final mediaType = data['media_type'];
            final url = data['url'];
            final title = data['title'];
            final explanation = data['explanation'];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (mediaType == 'image')
                    Image.network(url)
                  else if (mediaType == 'video')
                    const Center(
                      child: Text(
                        'Video available\nClick the View on NASA APOD button',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(explanation),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () async {
                      final uri = Uri.parse(data['hdurl'] ?? url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        throw 'Could not launch $uri';
                      }
                    },
                    child: const Text('View on NASA APOD'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
