# PetCare — Trabalho Final DDM

Aplicativo Flutter para tutores registrarem a saúde dos pets: pets, clínicas veterinárias, consultas e vacinas.

- **Estado:** Cubit (`flutter_bloc`)
- **Banco local:** SQLite (`sqflite`); o app lê sempre do banco local e funciona offline
- **API:** Supabase (REST + Auth + Storage), com sincronização dos pendentes ao reconectar
- **Recursos nativos:** câmera/galeria (`image_picker`) e GPS + mapa (`geolocator`, `flutter_map`)

## Como rodar

### 1. Gerar as pastas de plataforma

A pasta tem só `lib/` e `pubspec.yaml`. Na raiz do projeto, rode:

```bash
flutter create . --project-name petcare --platforms android,windows,web
flutter pub get
```

### 2. Configurar o Supabase

1. No painel do Supabase, abra **SQL Editor**, cole o conteúdo de `supabase/schema.sql` e rode.
   Ele cria as 4 tabelas, as regras de segurança (cada usuário só vê os próprios dados) e o bucket `petcare` de fotos.
2. Em **Authentication > Sign In / Providers > Email**, desative **Confirm email** (senão o login logo após o cadastro falha).
3. Em **Project Settings > API**, copie a URL e a chave *publishable/anon* para `lib/config/supabase_config.dart`.

### 3. Permissões no Android

Em `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>` e antes de `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />

<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
</queries>
```

### 4. Rodar

```bash
flutter run
```

Para testar câmera e GPS, use um celular ou o emulador Android. No Windows, a galeria e o mapa funcionam; a câmera não. Na versão web, fotos não são suportadas.

## Estrutura

```
lib/
  config/        URL e chave do Supabase
  models/        Pet, Clinica, Consulta, Vacina, Usuario (+ SyncStatus)
  database/      Banco SQLite e criação das tabelas
  repositories/  Acesso ao banco local (LocalRepository genérico) e autenticação
  services/      API REST do Supabase, sincronização, sessão, câmera e GPS
  cubits/        AuthCubit, SyncCubit, PetCubit, ClinicaCubit, ConsultaCubit, VacinaCubit, FormularioCubit
  views/         Telas e widgets
supabase/
  schema.sql     Tabelas, RLS e Storage
```

## Como funciona o offline-first

- Cada tabela local tem `updated_at`, `sync_status` (`synced`, `pending_create`, `pending_update`, `pending_delete`) e `deleted`.
- Cadastrar, editar e remover gravam só no SQLite e marcam o registro como pendente.
- O `SyncCubit` sincroniza ao abrir o app, quando a internet volta, após cada alteração e ao tocar no ícone de nuvem.
- A sincronização envia os pendentes (clínicas e pets primeiro), envia as remoções (filhos primeiro), sobe as fotos ao Storage e baixa o que mudou no servidor. Em conflito, vale a alteração mais recente.
- A sessão fica salva no aparelho, então o app abre sem internet depois do primeiro login.

## Estados tratados nas telas

Listas: `ListaInitial`, `ListaLoading`, `ListaLoaded`, `ListaEmpty`, `ListaError`.
Formulários: `FormularioInitial`, `FormularioSaving`, `FormularioSaved`, `FormularioError`.
Sincronização: `offline`, `sincronizando`, `sincronizado`, `erro` + quantidade de pendentes.
