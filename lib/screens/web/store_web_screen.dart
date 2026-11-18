import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../services/web_navigation.dart';

/// In-app view of a titepo.com / Shopify page — customer account,
/// live order status, policies, etc.
class StoreWebScreen extends StatefulWidget {
  final String url;
  final String title;

  const StoreWebScreen({super.key, required this.url, required this.title});

  static Future<void> open(BuildContext context, String url, String title) {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => StoreWebScreen(url: url, title: title)));
  }

  @override
  State<StoreWebScreen> createState() => _StoreWebScreenState();
}

class _StoreWebScreenState extends State<StoreWebScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        onNavigationRequest: (request) async {
          if (WebNavigation.isExternal(request.url)) {
            await WebNavigation.launchExternal(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _controller.reload(),
            ),
            IconButton(
              tooltip: 'Open in browser',
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () async {
                final current = await _controller.currentUrl() ?? widget.url;
                await launchUrl(Uri.parse(current), mode: LaunchMode.externalApplication);
              },
            ),
          ],
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 3,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primarySoft,
                  ),
                )
              : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
