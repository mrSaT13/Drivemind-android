import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'app_theme.dart';

class ThemeState {
  final PresetTheme preset;
  final bool gradient;
  final bool dynamicColor;
  final ThemeMode mode;
  final bool autoTime;
  const ThemeState({this.preset = PresetTheme.midnight, this.gradient = true, this.dynamicColor = true, this.mode = ThemeMode.dark, this.autoTime = false});
  ThemeState copyWith({PresetTheme? preset, bool? gradient, bool? dynamicColor, ThemeMode? mode, bool? autoTime}) =>
      ThemeState(preset: preset ?? this.preset, gradient: gradient ?? this.gradient, dynamicColor: dynamicColor ?? this.dynamicColor, mode: mode ?? this.mode, autoTime: autoTime ?? this.autoTime);
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) { _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = ThemeState(
      preset: PresetTheme.values[p.getInt('preset') ?? 0],
      gradient: p.getBool('gradient') ?? true,
      dynamicColor: p.getBool('dynamicColor') ?? true,
      mode: ThemeMode.values[p.getInt('mode') ?? 2],
      autoTime: p.getBool('autoTime') ?? false,
    );
  }
  Future<void> setPreset(PresetTheme v) async { state = state.copyWith(preset: v); (await SharedPreferences.getInstance()).setInt('preset', v.index); }
  Future<void> setGradient(bool v) async { state = state.copyWith(gradient: v); (await SharedPreferences.getInstance()).setBool('gradient', v); }
  Future<void> setDynamic(bool v) async { state = state.copyWith(dynamicColor: v); (await SharedPreferences.getInstance()).setBool('dynamicColor', v); }
  Future<void> setMode(ThemeMode v) async { state = state.copyWith(mode: v); (await SharedPreferences.getInstance()).setInt('mode', v.index); }
  Future<void> setAutoTime(bool v) async { state = state.copyWith(autoTime: v); (await SharedPreferences.getInstance()).setBool('autoTime', v); }
}

ThemeMode effectiveMode(ThemeState s) {
  if (s.autoTime) { final h = DateTime.now().hour; return (h < 7 || h >= 19) ? ThemeMode.dark : ThemeMode.light; }
  return s.mode;
}

ThemeData buildTheme(ThemeState s, ColorScheme? dyn) {
  if (effectiveMode(s) == ThemeMode.light) return AppTheme.lightFrom(s.preset);
  return AppTheme.build(s.preset, s.dynamicColor, dyn, s.gradient);
}
