-- ============================================================================
-- supabase-setup.sql — (ทางเลือก) ตารางเก็บรายงานสำหรับ Live Viewer ใน admin.html
-- ----------------------------------------------------------------------------
-- ⚠️ PDPA: ตารางนี้เก็บข้อมูลส่วนบุคคล/อ่อนไหว
--    RLS ด้านล่าง "ปิด" การเข้าถึงของ anon โดยดีฟอลต์ (ปลอดภัยไว้ก่อน)
--    - เขียนข้อมูล: ให้ Power Automate ใช้ SERVICE ROLE key (ฝั่ง server เท่านั้น
--      ห้ามใส่ service key ในฟอร์ม/หน้าเว็บเด็ดขาด)
--    - อ่านข้อมูล: ควรใช้ Supabase Auth (ผู้ใช้ที่ล็อกอิน) ไม่ใช่ anon key บนหน้า public
-- รันใน Supabase → SQL Editor
-- ============================================================================

create table if not exists public.alcohol_reports (
  id            uuid primary key default gen_random_uuid(),
  "caseId"      text unique not null,
  site          text not null,
  "testDate"    date,
  "personType"  text,
  "fullName"    text,
  company       text,
  "licensePlate" text,
  result1       text,
  time1         text,
  result2       text,
  time2         text,
  severity      text,
  "photoUrl"    text,
  reporter      text,
  notes         text,
  "submittedAt" timestamptz,
  inserted_at   timestamptz default now()
);

comment on table public.alcohol_reports is 'PDPA: personal/sensitive data. RLS denies anon by default.';

-- เปิด RLS (สำคัญ) — ไม่มี policy = ไม่มีใครอ่าน/เขียนผ่าน anon ได้
alter table public.alcohol_reports enable row level security;

-- ดัชนีช่วยกรอง
create index if not exists idx_alcohol_site on public.alcohol_reports (site);
create index if not exists idx_alcohol_date on public.alcohol_reports ("testDate");
create index if not exists idx_alcohol_submitted on public.alcohol_reports ("submittedAt" desc);

-- ----------------------------------------------------------------------------
-- Policy สำหรับ "อ่าน" — เปิดใช้เฉพาะเมื่อคุณต่อ Supabase Auth เข้ากับ admin แล้ว
-- (อนุญาตเฉพาะผู้ที่ authenticated เท่านั้น)
-- ----------------------------------------------------------------------------
-- create policy "authenticated read"
--   on public.alcohol_reports
--   for select
--   to authenticated
--   using (true);

-- ⛔️ อย่าสร้าง policy select ให้ role "anon" กับตารางนี้ (ข้อมูลอ่อนไหว)
-- ----------------------------------------------------------------------------
-- การเขียนจาก Power Automate: ใช้ HTTP action ยิงเข้า
--   POST  {SUPABASE_URL}/rest/v1/alcohol_reports
--   Headers: apikey = <SERVICE_ROLE_KEY> , Authorization = Bearer <SERVICE_ROLE_KEY>,
--            Content-Type = application/json , Prefer = return=minimal
--   Body: { "caseId": "...", "site": "...", ... }   (คีย์ตรงกับคอลัมน์)
-- service role bypass RLS ได้ และต้องอยู่ใน Power Automate (ฝั่ง server) เท่านั้น
-- ============================================================================
