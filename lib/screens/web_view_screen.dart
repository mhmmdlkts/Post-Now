import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String popOnLoad;
  final VoidCallback callback;
  WebViewScreen(this.url, this.callback, {this.popOnLoad});

  @override
  _WebViewScreen createState() => _WebViewScreen();
}

class _WebViewScreen extends State<WebViewScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _webView(),
          _backButton()
        ],
      ),
    );
  }

  Widget _backButton() {
    return Positioned(
          left: 0,
          top: 50,
          child: SafeArea(
            child: Material(
              color: Colors.black,
              borderRadius: BorderRadius.horizontal(right: Radius.circular(15)),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.only(top: 15, bottom: 15, left: 25, right: 15),
                  child: Icon(Icons.arrow_back_rounded, color: Colors.white,),
                ),
              )
            )
          )
    );
  }

  Widget _webView() {
    return InAppWebView(
      initialUrl: widget.url,
      initialHeaders: {},
      initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            debuggingEnabled: true,
          )
      ),
      onLoadStop: (InAppWebViewController controller, String url) async {
        if (widget.popOnLoad == null)
          return;
        print('onLoadStop' + url);
        if (url.contains(widget.popOnLoad))
          Navigator.pop(context, true);
      },
    );
  }

}