import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/screens/learning_hub_screen.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('adds DOB from the Learning access state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = _FakeLearningService();

    await tester.pumpWidget(
      MaterialApp(home: LearningHubScreen(service: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add your date of birth to access Learning.'),
        findsOneWidget);
    expect(find.text('Add DOB'), findsOneWidget);

    await tester.tap(find.text('Add DOB'));
    await tester.pumpAndSettle();

    expect(find.text('Select your date of birth'), findsOneWidget);
    expect(find.text('Save DOB'), findsOneWidget);

    await tester.tap(find.text('Save DOB'));
    await tester.pumpAndSettle();

    expect(service.updatedDateOfBirth, isNotNull);
    expect(find.text('Empuan Learning'), findsOneWidget);
    expect(find.text('Choose a topic'), findsOneWidget);
  });
}

class _FakeLearningService extends LearningService {
  DateTime? updatedDateOfBirth;

  @override
  Future<LearningHomeData> getHome() async {
    if (updatedDateOfBirth == null) {
      throw const LearningApiException(
        'Add your date of birth to your profile to access Learning.',
        statusCode: 403,
      );
    }

    return const LearningHomeData(
      categories: [],
      recommendedCourses: [],
      continueLearning: [],
    );
  }

  @override
  Future<void> updateDateOfBirth(DateTime dateOfBirth) async {
    updatedDateOfBirth = dateOfBirth;
  }
}
