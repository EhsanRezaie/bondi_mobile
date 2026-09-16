import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/services/local_notifications.dart';

void main() {
  group('LocalNotifications.parseContent', () {
    test('reads title/body/image/id from the data payload', () {
      final c = LocalNotifications.parseContent({
        'title': 'New message',
        'body': 'Ali sent you a message',
        'image_url': 'https://cdn.example/avatar.jpg',
        'notification_id': 'abc-123',
      });

      expect(c.title, 'New message');
      expect(c.body, 'Ali sent you a message');
      expect(c.imageUrl, 'https://cdn.example/avatar.jpg');
      expect(c.id, 'abc-123');
    });

    test('falls back to the notification block and message id', () {
      final c = LocalNotifications.parseContent(
        const {},
        fallbackTitle: 'Fallback title',
        fallbackBody: 'Fallback body',
        fallbackId: 'msg-id',
      );

      expect(c.title, 'Fallback title');
      expect(c.body, 'Fallback body');
      expect(c.imageUrl, isNull);
      expect(c.id, 'msg-id');
    });
  });
}
