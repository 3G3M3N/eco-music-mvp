import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViewIds = {};

Widget buildPlatformIframe({
  required String viewId,
  required String embedUrl,
  required String originalUrl,
}) {
  if (!_registeredViewIds.contains(viewId)) {
    _registeredViewIds.add(viewId);
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) {
        final iframe =
            web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src = embedUrl;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.style.backgroundColor = '#070709';
        iframe.allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share';
        iframe.allowFullscreen = true;
        return iframe;
      },
    );
  }

  return HtmlElementView(viewType: viewId);
}
