import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart' as sqflite show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'cubits/auth_cubit.dart';
import 'cubits/auth_state.dart';
import 'cubits/clinica_cubit.dart';
import 'cubits/pet_cubit.dart';
import 'cubits/sync_cubit.dart';
import 'repositories/auth_repository.dart';
import 'repositories/clinica_repository.dart';
import 'repositories/historico_repositories.dart';
import 'repositories/pet_repository.dart';
import 'services/eventos_dados.dart';
import 'services/foto_service.dart';
import 'services/localizacao_service.dart';
import 'services/sessao_service.dart';
import 'services/supabase_api.dart';
import 'services/sync_service.dart';
import 'views/home_page.dart';
import 'views/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _configurarBancoDeDados();

  final sessao = SessaoService(AuthRepository());
  runApp(PetCareApp(sessao: sessao));
}

/// Escolhe a implementação do SQLite de acordo com a plataforma.
void _configurarBancoDeDados() {
  if (kIsWeb) {
    databaseFactory = createDatabaseFactoryFfiWeb(noWebWorker: true);
  } else if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    databaseFactory = sqflite.databaseFactorySqflitePlugin;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

class PetCareApp extends StatelessWidget {
  final SessaoService sessao;
  const PetCareApp({super.key, required this.sessao});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(repository: sessao.authRepository, sessao: sessao)..verificarSessao(),
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (anterior, atual) => anterior.runtimeType != atual.runtimeType,
        builder: (context, state) {
          return switch (state) {
            AuthInitial() => _app(const Scaffold(body: Center(child: CircularProgressIndicator()))),
            Authenticated(:final usuario) => AreaLogada(key: ValueKey(usuario.id), sessao: sessao),
            _ => _app(const LoginPage()),
          };
        },
      ),
    );
  }
}

MaterialApp _app(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'PetCare',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.teal, foregroundColor: Colors.white),
    ),
    home: home,
  );
}

/// Cria as dependências do usuário logado e disponibiliza para todas as telas.
class AreaLogada extends StatefulWidget {
  final SessaoService sessao;
  const AreaLogada({super.key, required this.sessao});

  @override
  State<AreaLogada> createState() => _AreaLogadaState();
}

class _AreaLogadaState extends State<AreaLogada> {
  late final EventosDados _eventos;
  late final LocalizacaoService _localizacao;
  late final ConsultaRepository _consultas;
  late final VacinaRepository _vacinas;
  late final PetRepository _pets;
  late final ClinicaRepository _clinicas;
  late final SyncService _sync;

  @override
  void initState() {
    super.initState();
    final sessao = widget.sessao;
    _eventos = EventosDados();
    _localizacao = LocalizacaoService();
    _consultas = ConsultaRepository(sessao: sessao);
    _vacinas = VacinaRepository(sessao: sessao);
    _pets = PetRepository(sessao: sessao, consultas: _consultas, vacinas: _vacinas);
    _clinicas = ClinicaRepository(sessao: sessao, consultas: _consultas, vacinas: _vacinas);
    _sync = SyncService(
      api: SupabaseApi(sessao),
      sessao: sessao,
      fotoService: FotoService(),
      repositorios: [_clinicas, _pets, _consultas, _vacinas],
    );
  }

  @override
  void dispose() {
    _eventos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessao = widget.sessao;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: sessao),
        RepositoryProvider.value(value: _eventos),
        RepositoryProvider.value(value: _localizacao),
        RepositoryProvider.value(value: _consultas),
        RepositoryProvider.value(value: _vacinas),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => PetCubit(repository: _pets, sessao: sessao, eventos: _eventos)..carregar(),
          ),
          BlocProvider(
            create: (_) => ClinicaCubit(
              repository: _clinicas,
              sessao: sessao,
              localizacao: _localizacao,
              eventos: _eventos,
            )..carregar(),
          ),
          BlocProvider(
            lazy: false,
            create: (_) => SyncCubit(syncService: _sync, eventos: _eventos)..iniciar(),
          ),
        ],
        child: _app(const HomePage()),
      ),
    );
  }
}
