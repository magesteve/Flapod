import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(FlapodApp());
}

class FlapodApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flapod',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FlapodHomePage(),
    );
  }
}

class FlapodHomePage extends StatefulWidget {
  @override
  _FlapodHomePageState createState() => _FlapodHomePageState();
}

class _FlapodHomePageState extends State<FlapodHomePage> {
  String apiKey = '';

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    String key = await DefaultAssetBundle.of(context).loadString('assets/key.txt');
    setState(() {
      apiKey = key.trim();
    });
  }

  Future<Map<String, dynamic>> fetchApodData() async {
    final response = await http.get(Uri.parse(
        'https://api.nasa.gov/planetary/apod?api_key=$apiKey'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load APOD data');
    }
  }

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<List<TextSpan>> _loadFaq() async {
    String data = await DefaultAssetBundle.of(context).loadString("assets/FAQ.txt");
    List<String> lines = LineSplitter().convert(data);
    if (lines.length % 2 != 0) {
      lines.removeLast();
    }

    List<TextSpan> spans = [];
    for (String line in lines) {
      spans.add(_buildTextSpan(line));
      spans.add(TextSpan(text: '\n'));
    }

    return spans;
  }

  TextSpan _buildTextSpan(String text) {
    final urlRegExp = RegExp(r"(https?:\/\/[^\s]+)");
    final matches = urlRegExp.allMatches(text);

    if (matches.isEmpty) {
      return TextSpan(text: text);
    }

    List<TextSpan> children = [];
    int lastMatchEnd = 0;

    for (var match in matches) {
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final url = text.substring(match.start, match.end);
      children.add(
        TextSpan(
          text: url,
          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _launchURL(url);
            },
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      children.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return TextSpan(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flapod'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () async {
              List<TextSpan> faq = await _loadFaq();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("FAQ"),
                    content: SingleChildScrollView(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: faq,
                        ),
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text("Close"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: apiKey.isEmpty
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<Map<String, dynamic>>(
              future: fetchApodData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Unable to load image today",
                      style: TextStyle(color: Colors.red, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  );
                } else if (snapshot.hasData) {
                  var data = snapshot.data!;
                  if (data['media_type'] == 'video') {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Text(data['title'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(data['date']),
                          SizedBox(height: 20),
                          Text(
                            "Video available",
                            style: TextStyle(color: Colors.red, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "Click the View on NASA APOD button",
                            style: TextStyle(color: Colors.red, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(data['explanation']),
                          ),
                          TextButton(
                            onPressed: () => _launchURL(data['url']),
                            child: Text("View on NASA APOD"),
                            style: TextButton.styleFrom(
                              side: BorderSide(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Text(data['title'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(data['date']),
                          SizedBox(height: 20),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            child: Image.network(
                              data['url'],
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(data['explanation']),
                          ),
                          TextButton(
                            onPressed: () => _launchURL(data['url']),
                            child: Text("View on NASA APOD"),
                            style: TextButton.styleFrom(
                              side: BorderSide(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  return Center(child: Text('No data'));
                }
              },
            ),
    );
  }
}
