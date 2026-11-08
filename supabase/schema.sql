-- PetCare - estrutura do banco no Supabase
-- Execute no Supabase: SQL Editor > New query > cole tudo > Run.

-- ---------- Tabelas ----------

create table if not exists public.clinicas (
  id uuid primary key,
  tutor_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nome text not null,
  telefone text,
  endereco text,
  latitude double precision,
  longitude double precision,
  updated_at timestamptz not null default now()
);

create table if not exists public.pets (
  id uuid primary key,
  tutor_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nome text not null,
  especie text not null,
  raca text,
  sexo char(1) not null check (sexo in ('M', 'F')),
  data_nascimento date,
  peso_kg double precision,
  observacoes text,
  foto_url text,
  updated_at timestamptz not null default now()
);

create table if not exists public.consultas (
  id uuid primary key,
  tutor_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  pet_id uuid not null references public.pets(id) on delete cascade,
  clinica_id uuid not null references public.clinicas(id) on delete restrict,
  data_hora timestamptz not null,
  veterinario text,
  motivo text not null,
  diagnostico text,
  prescricao text,
  valor numeric(10, 2),
  foto_url text,
  updated_at timestamptz not null default now()
);

create table if not exists public.vacinas (
  id uuid primary key,
  tutor_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  pet_id uuid not null references public.pets(id) on delete cascade,
  clinica_id uuid references public.clinicas(id) on delete set null,
  nome text not null,
  lote text,
  data_aplicacao date not null,
  proxima_dose date check (proxima_dose is null or proxima_dose > data_aplicacao),
  foto_url text,
  updated_at timestamptz not null default now()
);

create index if not exists idx_consultas_pet on public.consultas(pet_id);
create index if not exists idx_vacinas_pet on public.vacinas(pet_id);

-- ---------- Row Level Security: cada tutor só acessa os próprios dados ----------

alter table public.clinicas enable row level security;
alter table public.pets enable row level security;
alter table public.consultas enable row level security;
alter table public.vacinas enable row level security;

drop policy if exists "dono_clinicas" on public.clinicas;
create policy "dono_clinicas" on public.clinicas
  for all using (auth.uid() = tutor_id) with check (auth.uid() = tutor_id);

drop policy if exists "dono_pets" on public.pets;
create policy "dono_pets" on public.pets
  for all using (auth.uid() = tutor_id) with check (auth.uid() = tutor_id);

drop policy if exists "dono_consultas" on public.consultas;
create policy "dono_consultas" on public.consultas
  for all using (auth.uid() = tutor_id) with check (auth.uid() = tutor_id);

drop policy if exists "dono_vacinas" on public.vacinas;
create policy "dono_vacinas" on public.vacinas
  for all using (auth.uid() = tutor_id) with check (auth.uid() = tutor_id);

-- ---------- Storage: bucket público para as fotos ----------
-- Cada usuário só pode enviar arquivos para a pasta com o próprio id.

insert into storage.buckets (id, name, public)
values ('petcare', 'petcare', true)
on conflict (id) do nothing;

drop policy if exists "petcare_upload" on storage.objects;
create policy "petcare_upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'petcare' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "petcare_update" on storage.objects;
create policy "petcare_update" on storage.objects
  for update to authenticated
  using (bucket_id = 'petcare' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "petcare_leitura" on storage.objects;
create policy "petcare_leitura" on storage.objects
  for select using (bucket_id = 'petcare');
