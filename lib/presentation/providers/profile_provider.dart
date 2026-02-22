import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmergencyContact {
  const EmergencyContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

class ProfileState {
  const ProfileState({
    required this.contacts,
    required this.language,
    required this.locationEnabled,
    required this.notificationsEnabled,
    required this.vpnEnabled,
    required this.darkMode,
  });

  final List<EmergencyContact> contacts;
  final String language;
  final bool locationEnabled;
  final bool notificationsEnabled;
  final bool vpnEnabled;
  final bool darkMode;

  ProfileState copyWith({
    List<EmergencyContact>? contacts,
    String? language,
    bool? locationEnabled,
    bool? notificationsEnabled,
    bool? vpnEnabled,
    bool? darkMode,
  }) {
    return ProfileState(
      contacts: contacts ?? this.contacts,
      language: language ?? this.language,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      vpnEnabled: vpnEnabled ?? this.vpnEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class ProfileController extends Notifier<AsyncValue<ProfileState>> {
  @override
  AsyncValue<ProfileState> build() {
    _load();
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    state = AsyncValue.data(
      const ProfileState(
        contacts: [
          EmergencyContact(name: 'Ayesha Perera', phone: '+94 77 123 4567'),
          EmergencyContact(name: 'Navin Silva', phone: '+94 71 555 0199'),
          EmergencyContact(name: 'Tourist Police', phone: '119'),
        ],
        language: 'English',
        locationEnabled: true,
        notificationsEnabled: true,
        vpnEnabled: true,
        darkMode: true,
      ),
    );
  }

  Future<void> retry() async {
    state = const AsyncValue.loading();
    await _load();
  }

  void addContact(EmergencyContact contact) {
    state = state.whenData((value) {
      return value.copyWith(contacts: [...value.contacts, contact]);
    });
  }

  void deleteContact(EmergencyContact contact) {
    state = state.whenData((value) {
      return value.copyWith(
        contacts: value.contacts
            .where((existing) =>
                existing.name != contact.name ||
                existing.phone != contact.phone)
            .toList(),
      );
    });
  }

  void updateLanguage(String language) {
    state = state.whenData((value) => value.copyWith(language: language));
  }

  void toggleLocation(bool enabled) {
    state = state.whenData((value) => value.copyWith(locationEnabled: enabled));
  }

  void toggleNotifications(bool enabled) {
    state =
        state.whenData((value) => value.copyWith(notificationsEnabled: enabled));
  }

  void toggleVpn(bool enabled) {
    state = state.whenData((value) => value.copyWith(vpnEnabled: enabled));
  }

  void toggleTheme(bool enabled) {
    state = state.whenData((value) => value.copyWith(darkMode: enabled));
  }
}

final profileProvider =
    NotifierProvider<ProfileController, AsyncValue<ProfileState>>(
  ProfileController.new,
);
