import 'dart:html' as html;

void updateBrowserUrl(String newUrl) {
  html.window.history.replaceState(null, 'Job Details', newUrl);
}

void listenToUrlChanges(void Function(String) onChanged) {
  html.window.onPopState.listen((_) {
    onChanged(html.window.location.href);
  });
}