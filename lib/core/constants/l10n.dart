import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'intl/messages_all.dart'; // TODO: intl generate_from_arb ile oluşturulmalı

class S {
    String get adminPanel => Intl.message('Admin Paneli', name: 'adminPanel');
    String get announcementManagement => Intl.message('Duyuru Yönetimi', name: 'announcementManagement');
    String get examManagement => Intl.message('Sınav Sonucu Yönetimi', name: 'examManagement');
    String get scheduleManagement => Intl.message('Ders Programı Yönetimi', name: 'scheduleManagement');
    String get userManagement => Intl.message('Öğrenci Yönetimi', name: 'userManagement');
  static Future<S> load(Locale locale) {
    final String name = locale.countryCode?.isEmpty ?? true
        ? locale.languageCode
        : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);
    // Lokalizasyon yüklemesi devre dışı bırakıldı (intl ARB dosyası eksik olduğu için)
    Intl.defaultLocale = localeName;
    return Future.value(S());
  }

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  String get appTitle => Intl.message('UNITY4 ACADEMY', name: 'appTitle');
  String get signIn => Intl.message('Sign In', name: 'signIn');
  String get email => Intl.message('Email', name: 'email');
  String get password => Intl.message('Password', name: 'password');
  String get invalidEmail => Intl.message('Enter a valid email', name: 'invalidEmail');
  String get minPassword => Intl.message('At least 6 characters', name: 'minPassword');
  String welcome(String role) => Intl.message('Welcome, $role', name: 'welcome', args: [role]);
  String get dashboard => Intl.message('Dashboard', name: 'dashboard');
  String get announcements => Intl.message('Announcements', name: 'announcements');
  String get messages => Intl.message('Messages', name: 'messages');
  String get settings => Intl.message('Settings', name: 'settings');
  String get sendMessage => Intl.message('Type a message...', name: 'sendMessage');
}

class SDelegate extends LocalizationsDelegate<S> {
  const SDelegate();

  @override
  bool isSupported(Locale locale) => ['tr', 'en', 'ru', 'ar', 'uz'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) => S.load(locale);

  @override
  bool shouldReload(SDelegate old) => false;
}
