import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opportune_bf/app/features/trainings/domain/entities/training.dart';
import 'package:opportune_bf/app/features/trainings/presentation/widgets/training_card.dart';

Training _training() => const Training(
      id: 't1',
      title: 'Bases de la comptabilité',
      providerName: 'OpporTune Academy',
      location: 'Ouagadougou',
      format: 'En ligne',
      level: 'Débutant',
      lessons: 3,
      rating: 4.5,
      enrolledCount: 25,
      status: 'active',
      priceLabel: '25 000 FCFA',
      price: 25000,
      sector: 'Finance',
      description: 'Une formation pratique.',
      durationLabel: '3 heures',
      startDateLabel: '',
      deadlineLabel: '',
      certificationLabel: 'Aucun',
      languageLabel: 'Français',
      objectives: [],
      requirements: [],
      modules: [],
      contactLabel: '',
      isBookmarked: false,
      isEnrolled: false,
      coverUrl: '', // pas d'image → fallback de marque (aucun réseau en test)
    );

void main() {
  testWidgets('TrainingCard (parallax) builds in a scrollable without throwing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              TrainingCard(training: _training()),
              const SizedBox(height: 200),
              TrainingCard(training: _training()),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(TrainingCard), findsWidgets);

    // Petit scroll : déclenche le repaint parallax (Flow delegate) en gardant
    // au moins une carte visible.
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pump();

    expect(find.byType(TrainingCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
