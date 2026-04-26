import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../widgets/widgets.dart';
import '../../core/security/auth_token_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'home_controller.dart';


part 'home_training_parts/payment_screen.dart';
part 'home_training_parts/lesson_screen.dart';
part 'home_training_parts/shared_widgets.dart';

void openFormationPayment(
  HomeController controller,
  HomeFormationPreview formation,
) {
  Get.to<void>(
    () => FormationPaymentScreen(
      controller: controller,
      formation: formation,
    ),
    transition: Transition.rightToLeft,
  );
}

/// Ouvre directement le lecteur de lecon (sans passer par l'ecran Programme).
/// La page de detail joue desormais le role de hub : liste les lecons,
/// affiche la progression, et delegue la lecture a [FormationLessonScreen].
void openFormationLesson(
  HomeController controller,
  HomeFormationPreview formation,
  int initialIndex,
) {
  Get.to<void>(
    () => FormationLessonScreen(
      controller: controller,
      formation: formation,
      initialIndex: initialIndex,
    ),
    transition: Transition.rightToLeft,
  );
}

