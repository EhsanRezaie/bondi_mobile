import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/providers/ticket_provider.dart';
import 'package:dating_app/screens/profile/tickets_screen.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/mock_api.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  Map<String, dynamic> ticket({
    String id = 't-1',
    String subject = 'Payment / Premium',
    String message = 'Please help me',
    String status = 'open',
  }) {
    return {
      'id': id,
      'user_id': 'u-1',
      'subject': subject,
      'message': message,
      'status': status,
      'admin_response': null,
      'created_at': '2026-08-05T12:00:00.000',
      'updated_at': null,
      'messages': <Map<String, dynamic>>[],
    };
  }

  testWidgets('renders ticket list with subjects and statuses', (tester) async {    MockApi()
      ..onGet('/tickets', body: {
        'tickets': [
          ticket(id: 't-1', subject: 'Payment / Premium', status: 'open'),
          ticket(id: 't-2', subject: 'Photo verification', status: 'closed'),
          ticket(id: 't-3', subject: 'Account / Login issue', status: 'in_progress'),
        ],
        'total': 3,
        'next_offset': null,
      })
      ..install();

    await pumpApp(
      tester,
      const TicketsScreen(),
      providers: [ChangeNotifierProvider(create: (_) => TicketProvider())],
    );

    expect(find.text('My Tickets'), findsOneWidget);
    expect(find.text('Payment / Premium'), findsOneWidget);
    expect(find.text('Photo verification'), findsOneWidget);
    expect(find.text('Account / Login issue'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('New Ticket'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no tickets', (tester) async {
    MockApi()
      ..onGet('/tickets', body: {
        'tickets': <Map<String, dynamic>>[],
        'total': 0,
        'next_offset': null,
      })
      ..install();

    await pumpApp(
      tester,
      const TicketsScreen(),
      providers: [ChangeNotifierProvider(create: (_) => TicketProvider())],
    );

    expect(find.text('No tickets yet'), findsOneWidget);
    expect(find.text('New Ticket'), findsOneWidget);
  });
}