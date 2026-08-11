import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

/// Icônes sémantiques Baara — style SF Symbols (Cupertino) en priorité,
/// Material Rounded en fallback pour les pictos sans équivalent Cupertino.
abstract final class AppIcons {
  // Navigation
  static const IconData home = CupertinoIcons.house;
  static const IconData homeFilled = CupertinoIcons.house_fill;
  static const IconData work = CupertinoIcons.briefcase;
  static const IconData workFilled = CupertinoIcons.briefcase_fill;
  static const IconData network = CupertinoIcons.person_2;
  static const IconData networkFilled = CupertinoIcons.person_2_fill;
  static const IconData tracking = CupertinoIcons.square_grid_2x2;
  static const IconData trackingFilled = CupertinoIcons.square_grid_2x2_fill;
  static const IconData profile = CupertinoIcons.person_circle;
  static const IconData profileFilled = CupertinoIcons.person_circle_fill;
  static const IconData category = CupertinoIcons.square_grid_2x2;

  // Auth & formulaires
  static const IconData message = CupertinoIcons.mail;
  static const IconData messageFilled = CupertinoIcons.mail_solid;
  static const IconData lock = CupertinoIcons.lock;
  static const IconData lockFilled = CupertinoIcons.lock_fill;
  static const IconData unlock = CupertinoIcons.lock_open;
  static const IconData password = CupertinoIcons.lock_shield;
  static const IconData phone = CupertinoIcons.phone;
  static const IconData person = CupertinoIcons.person;
  static const IconData personFilled = CupertinoIcons.person_fill;
  static const IconData login = CupertinoIcons.arrow_right_square;
  static const IconData show = CupertinoIcons.eye;
  static const IconData hide = CupertinoIcons.eye_slash;
  static const IconData arrowRight = CupertinoIcons.arrow_right;
  static const IconData arrowLeft = CupertinoIcons.chevron_back;
  static const IconData back = CupertinoIcons.chevron_back;
  static const IconData close = CupertinoIcons.xmark;
  static const IconData closeSquare = CupertinoIcons.xmark_circle;
  static const IconData check = CupertinoIcons.checkmark;
  static const IconData checkCircle = CupertinoIcons.checkmark_circle_fill;
  static const IconData time = CupertinoIcons.time;
  static const IconData timeSquare = CupertinoIcons.clock;
  static const IconData search = CupertinoIcons.search;
  static const IconData send = CupertinoIcons.paperplane_fill;
  static const IconData refresh = CupertinoIcons.arrow_clockwise;
  static const IconData settings = CupertinoIcons.gear;
  static const IconData bell = CupertinoIcons.bell;
  static const IconData notification = CupertinoIcons.bell;
  static const IconData heart = CupertinoIcons.heart;
  static const IconData heartFilled = CupertinoIcons.heart_fill;
  static const IconData bookmark = CupertinoIcons.bookmark;
  static const IconData bookmarkFilled = CupertinoIcons.bookmark_fill;
  static const IconData share = CupertinoIcons.share;
  static const IconData add = CupertinoIcons.plus;
  static const IconData addUser = CupertinoIcons.person_add;
  static const IconData edit = CupertinoIcons.pencil;
  static const IconData delete = CupertinoIcons.trash;
  static const IconData info = CupertinoIcons.info_circle;
  static const IconData warning = CupertinoIcons.exclamationmark_triangle;
  static const IconData danger = CupertinoIcons.exclamationmark_triangle_fill;
  static const IconData error = CupertinoIcons.xmark_circle_fill;
  static const IconData success = CupertinoIcons.checkmark_seal_fill;
  static const IconData document = CupertinoIcons.doc_text;
  static const IconData paper = CupertinoIcons.doc;
  static const IconData paperPlus = CupertinoIcons.add_circled;
  static const IconData folder = CupertinoIcons.folder;
  static const IconData camera = CupertinoIcons.camera;
  static const IconData image = CupertinoIcons.photo;
  static const IconData location = CupertinoIcons.location;
  static const IconData calendar = CupertinoIcons.calendar;
  static const IconData filter = CupertinoIcons.slider_horizontal_3;
  static const IconData chevronDown = CupertinoIcons.chevron_down;
  static const IconData chevronRight = CupertinoIcons.chevron_right;
  static const IconData more = CupertinoIcons.ellipsis;
  static const IconData tickSquare = CupertinoIcons.checkmark_square_fill;
  static const IconData star = CupertinoIcons.star;
  static const IconData starFilled = CupertinoIcons.star_fill;
  static const IconData chat = CupertinoIcons.chat_bubble;
  static const IconData chatFilled = CupertinoIcons.chat_bubble_fill;
  static const IconData play = CupertinoIcons.play_fill;
  static const IconData video = CupertinoIcons.videocam;
  static const IconData voice = CupertinoIcons.mic;
  static const IconData upload = CupertinoIcons.cloud_upload;
  static const IconData download = CupertinoIcons.cloud_download;
  static const IconData wallet = CupertinoIcons.money_dollar_circle;
  static const IconData shield = CupertinoIcons.shield;
  static const IconData shieldDone = CupertinoIcons.checkmark_shield;
  static const IconData activity = CupertinoIcons.waveform_path_ecg;
  static const IconData chart = CupertinoIcons.chart_bar;
  static const IconData volumeUp = CupertinoIcons.speaker_2;
  static const IconData volumeOff = CupertinoIcons.speaker_slash;
  static const IconData call = CupertinoIcons.phone;
  static const IconData user = CupertinoIcons.person;
  static const IconData userFilled = CupertinoIcons.person_fill;

  static const IconData arrowUp = CupertinoIcons.arrow_up;
  static const IconData global = CupertinoIcons.globe;
  static const IconData discovery = CupertinoIcons.compass;
  static const IconData shieldFail = CupertinoIcons.shield_slash;
  static const IconData moreCircle = CupertinoIcons.ellipsis_circle;
  static const IconData arrowRightCircle = CupertinoIcons.arrow_right_circle;
  static const IconData swap = CupertinoIcons.arrow_2_squarepath;
  static const IconData logout = CupertinoIcons.square_arrow_right;
  static const IconData notificationFilled = CupertinoIcons.bell_fill;

  // Material fallbacks (pictos absents de Cupertino)
  static const IconData school = Icons.school_rounded;
}
