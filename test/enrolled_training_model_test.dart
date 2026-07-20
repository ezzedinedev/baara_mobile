import 'package:flutter_test/flutter_test.dart';
import 'package:jobaway/app/features/trainings/data/models/enrolled_training_model.dart';

/// Test de contrat : décode une ligne telle que la renvoie
/// `GET /trainings/enrolled/list` (TrainingApiController@enrolled).
/// Le backend ne charge la formation qu'en résumé :
/// `training:id,title,format,level,avg_rating,image_path`.
void main() {
  test('decode une inscription complete', () {
    final json = <String, dynamic>{
      'id': '019f5457-fa14-70bb-9b37-7637fbdc21fb',
      'training_id': '55ca8f92-d986-44a4-9612-a5e69f93e007',
      'progress_pct': 40,
      'is_completed': false,
      'modules_completed': ['mod-1', 'mod-2'],
      'enrolled_at': '2026-07-01T09:30:00.000000Z',
      'completed_at': null,
      'certificate_url': null,
      'payment_status': 'paid',
      'training': {
        'id': '55ca8f92-d986-44a4-9612-a5e69f93e007',
        'title': 'Marketing Digital & Stratégie de Contenu',
        'format': 'online',
        'level': 'beginner',
        'avg_rating': 4.5,
        'image_path': '/storage/trainings/cover.jpg',
      },
    };

    final e = EnrolledTrainingModel.fromJson(json);

    expect(e.enrollmentId, '019f5457-fa14-70bb-9b37-7637fbdc21fb');
    expect(e.training.title, 'Marketing Digital & Stratégie de Contenu');
    expect(e.training.rating, 4.5);
    expect(e.progressPct, 40);
    expect(e.isCompleted, isFalse);
    expect(e.completedModuleIds, ['mod-1', 'mod-2']);
    expect(e.enrolledAt?.year, 2026);
    expect(e.hasCertificate, isFalse);
    expect(e.paymentStatus, 'paid');
  });

  test('survit a une formation supprimee et a des champs absents', () {
    final e = EnrolledTrainingModel.fromJson({
      'id': 'enr-1',
      'training_id': 'trn-1',
      'training': null,
    });

    expect(e.enrollmentId, 'enr-1');
    expect(e.training.id, 'trn-1');
    expect(e.progressPct, 0);
    expect(e.completedModuleIds, isEmpty);
    expect(e.enrolledAt, isNull);
    expect(e.hasCertificate, isFalse);
  });

  test('expose le certificat une fois la formation terminee', () {
    final e = EnrolledTrainingModel.fromJson({
      'id': 'enr-2',
      'training_id': 'trn-2',
      'progress_pct': 100,
      'is_completed': true,
      'completed_at': '2026-07-10T12:00:00.000000Z',
      'certificate_url': '/storage/certificates/enr-2.pdf',
      'training': {'id': 'trn-2', 'title': 'Comptabilité'},
    });

    expect(e.isCompleted, isTrue);
    expect(e.progressPct, 100);
    expect(e.completedAt?.day, 10);
    expect(e.hasCertificate, isTrue);
  });
}
