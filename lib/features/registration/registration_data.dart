// Registration data - wizard state shared between steps.
// Step 12 confirm persists it via profile_service.createProfile
// (local JSON copy + Supabase upsert attempt when configured).
// No network call happens in this file itself.
import 'package:flutter/material.dart';

class RegistrationData {
  final String fullName;
  final String nickname;
  final String gender; // '', 'boy', 'girl'
  final int? schoolClass;
  final String medium; // '', 'bn', 'en'
  final String schoolName;
  final String district;
  final String phone;
  final String email;
  final String password;
  final String otp;
  final int dailyGoalMinutes;
  final String guardianName;
  final String guardianPhone;

  const RegistrationData({
    this.fullName = '',
    this.nickname = '',
    this.gender = '',
    this.schoolClass,
    this.medium = '',
    this.schoolName = '',
    this.district = '',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.otp = '',
    this.dailyGoalMinutes = 30,
    this.guardianName = '',
    this.guardianPhone = '',
  });

  RegistrationData copyWith({
    String? fullName,
    String? nickname,
    String? gender,
    int? schoolClass,
    String? medium,
    String? schoolName,
    String? district,
    String? phone,
    String? email,
    String? password,
    String? otp,
    int? dailyGoalMinutes,
    String? guardianName,
    String? guardianPhone,
  }) {
    return RegistrationData(
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      schoolClass: schoolClass ?? this.schoolClass,
      medium: medium ?? this.medium,
      schoolName: schoolName ?? this.schoolName,
      district: district ?? this.district,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      otp: otp ?? this.otp,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
    );
  }
}

/// Shared mock state for the wizard. Individual routes read/write this
/// so steps link up without router changes. Integration agent may
/// replace it with go_router `extra` passing instead.
final ValueNotifier<RegistrationData> registrationDataNotifier =
    ValueNotifier<RegistrationData>(const RegistrationData());

void updateRegistration(RegistrationData data) {
  registrationDataNotifier.value = data;
}

void resetRegistration() {
  registrationDataNotifier.value = const RegistrationData();
}
