-- Supabase 대시보드 → SQL Editor 에 붙여넣고 Run 하세요.

create table surveys (
  id text primary key,
  owner uuid not null default auth.uid(),
  title text,
  questions jsonb not null default '[]',
  rules jsonb not null default '[]',
  open boolean not null default true,
  created_at timestamptz not null default now()
);

create table responses (
  id bigint generated always as identity primary key,
  survey_id text not null references surveys(id) on delete cascade,
  answers jsonb not null,
  created_at timestamptz not null default now()
);

alter table surveys enable row level security;
alter table responses enable row level security;

-- 누구나: 열려 있는 설문의 질문만 읽기
create policy "read open surveys" on surveys
  for select using (open);

-- 로그인한 관리자: 자기 설문 생성/수정/삭제/조회
create policy "owner manages surveys" on surveys
  for all to authenticated
  using (owner = auth.uid()) with check (owner = auth.uid());

-- 누구나: 열려 있는 설문에 응답 제출만 가능 (읽기 불가)
create policy "anyone submits" on responses
  for insert to anon, authenticated
  with check (exists (select 1 from surveys s where s.id = survey_id and s.open));

-- 설문 주인만: 응답 조회
create policy "owner reads responses" on responses
  for select to authenticated
  using (exists (select 1 from surveys s where s.id = survey_id and s.owner = auth.uid()));
