import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String htmlContent;

  const PaymentWebViewPage({
    super.key,
    required this.htmlContent,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  bool _paymentCompleted = false; // Ödeme tamamlandı mı kontrolü

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _error = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Sayfa yüklendiğinde viewport ayarını zorla (mobil uyumluluk için)
            _controller.runJavaScript('''
              var meta = document.createElement('meta');
              meta.name = 'viewport';
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
              var head = document.getElementsByTagName('head')[0];
              if (head) {
                head.appendChild(meta);
              }
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _error = error.description.isNotEmpty ? error.description : 'Bir hata oluştu';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Log URL for debugging
            print('WebView navigating to: ${request.url}');
            
            // Ödeme başarılı/başarısız sayfalarına yönlendirme kontrolü
            final url = request.url.toLowerCase();
            
            // Başarılı ödeme URL'leri - tüm pattern'leri kontrol et
            // api.mandw.com.tr/api/v1/appointment/param/success
            // api.mandw.com.tr/api/v1/order/param/success
            // api.mandw.com.tr/api/v1/product/param/success
            // app.mandw.com.tr/v1/param/response?status=success
            if (!_paymentCompleted && 
                (url.contains('/param/success') || 
                 (url.contains('/param/response') && url.contains('status=success')) ||
                 (url.contains('/appointment/param/success')) ||
                 (url.contains('/order/param/success')) ||
                 (url.contains('/product/param/success')) ||
                 (url.contains('mandw.com.tr') && url.contains('param') && url.contains('success')))) {
              // Ödeme başarılı, geri dön
              print('PaymentWebView: Başarılı ödeme URL tespit edildi (onNavigationRequest): ${request.url}');
              _paymentCompleted = true;
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  print('PaymentWebView: Navigator.pop çağrılıyor (success)');
                  Navigator.pop(context, true); // true = ödeme başarılı
                }
              });
              return NavigationDecision.navigate;
            }
            
            // Başarısız ödeme URL'leri
            if (!_paymentCompleted && 
                (url.contains('/param/fail') || 
                 (url.contains('/param/response') && url.contains('status=fail')) ||
                 (url.contains('/appointment/param/fail')) ||
                 (url.contains('/order/param/fail')) ||
                 (url.contains('/product/param/fail')) ||
                 (url.contains('mandw.com.tr') && url.contains('param') && url.contains('fail')))) {
              // Ödeme başarısız, geri dön
              print('PaymentWebView: Başarısız ödeme URL tespit edildi (onNavigationRequest): ${request.url}');
              _paymentCompleted = true;
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  print('PaymentWebView: Navigator.pop çağrılıyor (fail)');
                  Navigator.pop(context, false); // false = ödeme başarısız
                }
              });
              return NavigationDecision.navigate;
            }
            
            // Allow all navigation - redirects will happen in WebView
            // Payment gateway will handle redirects
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            // Log URL changes for debugging
            if (change.url != null) {
              print('WebView URL changed to: ${change.url}');
              
              // Ödeme tamamlandı kontrolü
              final url = change.url!.toLowerCase();
              
              // Başarılı ödeme URL'leri - tüm pattern'leri kontrol et
              // api.mandw.com.tr/api/v1/appointment/param/success
              // api.mandw.com.tr/api/v1/order/param/success
              // api.mandw.com.tr/api/v1/product/param/success
              // app.mandw.com.tr/v1/param/response?status=success
              if (!_paymentCompleted && 
                  (url.contains('/param/success') || 
                   (url.contains('/param/response') && url.contains('status=success')) ||
                   (url.contains('/appointment/param/success')) ||
                   (url.contains('/order/param/success')) ||
                   (url.contains('/product/param/success')) ||
                   (url.contains('mandw.com.tr') && url.contains('param') && url.contains('success')))) {
                // Ödeme başarılı, geri dön
                print('PaymentWebView: Başarılı ödeme URL tespit edildi (onUrlChange): ${change.url}');
                _paymentCompleted = true;
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    print('PaymentWebView: Navigator.pop çağrılıyor (success)');
                    Navigator.pop(context, true);
                  }
                });
                return;
              }
              
              // Başarısız ödeme URL'leri
              if (!_paymentCompleted && 
                  (url.contains('/param/fail') || 
                   (url.contains('/param/response') && url.contains('status=fail')) ||
                   (url.contains('/appointment/param/fail')) ||
                   (url.contains('/order/param/fail')) ||
                   (url.contains('/product/param/fail')) ||
                   (url.contains('mandw.com.tr') && url.contains('param') && url.contains('fail')))) {
                // Ödeme başarısız, geri dön
                print('PaymentWebView: Başarısız ödeme URL tespit edildi (onUrlChange): ${change.url}');
                _paymentCompleted = true;
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    print('PaymentWebView: Navigator.pop çağrılıyor (fail)');
                    Navigator.pop(context, false);
                  }
                });
                return;
              }
            }
          },
        ),
      )
      ..loadHtmlString(
        _wrapHtmlContent(widget.htmlContent),
        baseUrl: 'https://api.mandw.com.tr',
      );
  }

  String _wrapHtmlContent(String html) {
    // If HTML already has proper structure, use it as is
    if (html.trim().startsWith('<!DOCTYPE') || html.trim().startsWith('<html')) {
      // Ensure viewport meta tag exists for proper mobile rendering
      if (!html.contains('viewport')) {
        // Insert viewport meta tag after <head> tag
        html = html.replaceFirst(
          '<head>',
          '<head>\n  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">',
        );
      }
      return html;
    }
    
    // Wrap in basic HTML structure
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * {
      box-sizing: border-box;
    }
    body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100vh;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      overflow-x: hidden;
    }
    form {
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  $html
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Ödeme İşlemi',
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Hata',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _error!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _isLoading = true;
                          });
                          _controller.reload();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: Text(
                          'Tekrar Dene',
                          style: AppTypography.buttonMedium.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox.expand(
                child: WebViewWidget(controller: _controller),
              ),
            if (_isLoading && _error == null)
              Container(
                color: AppColors.surface,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Yükleniyor...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

