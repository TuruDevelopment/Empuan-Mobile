import 'package:Empuan/data/content_repository.dart';
import 'package:Empuan/data/daily_quiz_repository.dart';
import 'package:Empuan/features/safety/sos_controller.dart';
import 'package:Empuan/data/contacts_repository.dart';
import 'package:Empuan/ui/em_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Place', () {
    const place = Place(id: 1, name: 'Bella Salon', address: 'Kemang', description: '', opensAt: '09:00', closesAt: '21:00', price: '150000');

    test('reports open and closed hours', () {
      expect(place.openStatus(DateTime(2026, 10, 23, 12))!.label, 'Open until 21:00');
      expect(place.openStatus(DateTime(2026, 10, 23, 22))!.label, 'Closed · opens 09:00');
    });

    test('handles places open past midnight', () {
      const late = Place(id: 2, name: 'Cafe', address: '', description: '', opensAt: '18:00', closesAt: '02:00');
      expect(late.openStatus(DateTime(2026, 10, 23, 1))!.open, isTrue);
      expect(late.openStatus(DateTime(2026, 10, 23, 12))!.open, isFalse);
    });

    test('formats rupiah prices', () {
      expect(place.priceLabel, 'From Rp 150.000');
    });

    test('has no status without hours', () {
      const unknown = Place(id: 3, name: 'X', address: '', description: '');
      expect(unknown.openStatus(), isNull);
    });
  });

  test('daily answers ignore case and spaces', () {
    const q = DailyQuestion(id: 1, prompt: 'Emergency number?', correctAnswer: '112');
    expect(q.isCorrect(' 112 '), isTrue);
    expect(q.isCorrect('110'), isFalse);
  });

  test('initials use the first two names', () {
    expect(initialsOf('Ayu Lestari Putri'), 'AL');
    expect(initialsOf('ayu'), 'A');
    expect(initialsOf('  '), '?');
  });

  test('relative times', () {
    final now = DateTime(2026, 10, 23, 15);
    expect(formatRelative(now.subtract(const Duration(seconds: 20)), now: now), 'Just now');
    expect(formatRelative(now.subtract(const Duration(minutes: 5)), now: now), '5 min ago');
    expect(formatRelative(DateTime(2026, 10, 22, 20), now: now), 'Yesterday');
    expect(formatRelative(DateTime(2026, 9, 1), now: now), '1 Sep');
  });

  test('SOS text includes a maps link only when location is known', () {
    expect(SosController.helpMessage(null), contains('couldn’t share my location'));
  });

  test('contact names read naturally', () {
    Contact c(String n) => Contact(id: 0, name: n, phone: '', relation: '');
    expect(namesList([c('Ibu')]), 'Ibu');
    expect(namesList([c('Ibu'), c('Rina')]), 'Ibu and Rina');
    expect(namesList([c('Ibu'), c('Rina'), c('Sari')]), 'Ibu, Rina and Sari');
  });
}
