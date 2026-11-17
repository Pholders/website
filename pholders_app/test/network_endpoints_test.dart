import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/core/api/http_client.dart';
import 'package:pholders_app/core/realtime/realtime_gateway.dart';
import 'package:pholders_app/shared/constants/app_constants.dart';

void main() {
  test('order HTTP client uses the configured API URL with a trailing slash',
      () {
    final dio = HttpClient.create(
      storage: const FlutterSecureStorage(),
      onUnauthorized: () {},
    );

    final expectedBaseUrl = AppConstants.apiBaseUrl.endsWith('/')
        ? AppConstants.apiBaseUrl
        : '${AppConstants.apiBaseUrl}/';
    expect(dio.options.baseUrl, expectedBaseUrl);
    expect(
      Uri.parse(dio.options.baseUrl).resolve('orders/15').path,
      '${Uri.parse(AppConstants.apiBaseUrl).path}/orders/15',
    );
  });

  test('realtime client uses the configured API host by default', () {
    final apiUri = Uri.parse(AppConstants.apiBaseUrl);
    final apiPath = apiUri.path.replaceFirst(RegExp(r'/api/?$'), '');
    final expectedUri = apiUri.replace(path: apiPath);

    expect(Uri.parse(RealtimeGateway.defaultWsUrl), expectedUri);
  });
}
