import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photographer/services/api_client.dart';

void main() {
  group('ApiClient', () {
    test('can be instantiated', () {
      final client = ApiClient();
      expect(client, isA<ApiClient>());
    });

    test('setAuthToken does not throw', () {
      final client = ApiClient();
      expect(() => client.setAuthToken('test-token'), returnsNormally);
    });

    test('clearAuthToken does not throw', () {
      final client = ApiClient();
      expect(() => client.clearAuthToken(), returnsNormally);
    });

    test('setAuthToken followed by clearAuthToken does not throw', () {
      final client = ApiClient();
      client.setAuthToken('test-token');
      expect(() => client.clearAuthToken(), returnsNormally);
    });

    test('multiple instances can be created independently', () {
      final client1 = ApiClient();
      final client2 = ApiClient();

      expect(client1, isA<ApiClient>());
      expect(client2, isA<ApiClient>());
      expect(identical(client1, client2), isFalse);
    });

    test('setAuthToken can be called multiple times', () {
      final client = ApiClient();
      client.setAuthToken('token-1');
      expect(() => client.setAuthToken('token-2'), returnsNormally);
    });
  });
}
