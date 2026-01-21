import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // Initialisation du contrôleur WebView
    _controller = WebViewController()
      // Autorise l'exécution du JavaScript
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Charge le fichier HTML local
      ..loadFlutterAsset('assets/license.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conditions d'utilisation"),
        backgroundColor: const Color(0xFF2c3e50),
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}
