import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

const _supabaseUrl = String.fromEnvironment('ALIM_SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('ALIM_SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Se inicializa siempre que haya credenciales, sin importar el motor
  // seleccionado por defecto: el selector de motor del Dev Mode permite
  // cambiar a 'supabase' en tiempo de ejecución.
  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
        url: _supabaseUrl, publishableKey: _supabaseAnonKey);
  }
  runApp(const ProviderScope(child: AlimApp()));
}
