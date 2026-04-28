import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/api_constants.dart';
import '../../translations/app_translations.dart';
import '../../core/services/auth_token_store.dart';
import '../../core/theme/app_theme_controller.dart';
import '../../core/utils/asset_url.dart';
import '../../core/network/api_provider.dart';
import 'home_profile_models.dart';

part 'home_profile_manager_parts/pdf_builders.dart';
part 'home_profile_manager_parts/parsing.dart';
part 'home_profile_manager_parts/loaders.dart';
part 'home_profile_manager_parts/saves.dart';

class HomeProfileManager {
  HomeProfileManager(this._apiProvider) : _tokenStore = const AuthTokenStore();

  static const cvTemplateOptions = <HomeCvTemplateOption>[
    HomeCvTemplateOption(
      id: 'international',
      label: 'International',
      description: 'Profil, experience, formation, certifications.',
    ),
    HomeCvTemplateOption(
      id: 'ats',
      label: 'ATS',
      description: 'Simple, lisible par les logiciels de recrutement.',
    ),
    HomeCvTemplateOption(
      id: 'executive',
      label: 'Executive',
      description: 'Mise en page plus premium pour profils confirmes.',
    ),
  ];

  final ApiProvider _apiProvider;
  final AuthTokenStore _tokenStore;

  final profile = const HomeUserProfile.empty().obs;
  final preferences = const HomeProfilePreferences.defaults().obs;
  final uploadedCv = const HomeUploadedCv.empty().obs;
  final selectedCvTemplate = 'international'.obs;
  final cvSections = <HomeCvSection>[].obs;
  final portfolioItems = <HomePortfolioItem>[].obs;

  final isLoadingProfile = false.obs;
  final isLoadingCv = false.obs;
  final isLoadingPortfolio = false.obs;
  final isSavingProfile = false.obs;
  final isSavingPreferences = false.obs;
  final isUploadingAvatar = false.obs;
  final isUploadingCvFile = false.obs;
  final isSavingCv = false.obs;
  final isSavingPortfolio = false.obs;
  final isExportingCv = false.obs;
  final isPreviewingCv = false.obs;

  final profileLoadError = ''.obs;
  final cvLoadError = ''.obs;
  final portfolioLoadError = ''.obs;

}
