-- Một Chiếc Lọ Đầy Yêu Thương: dán toàn bộ file này vào Supabase > SQL Editor > Run
-- File này chạy lại nhiều lần được, không bị lỗi trùng.
-- Đổi email bên dưới nếu tài khoản admin của bạn dùng email khác (có 3 chỗ).

create table if not exists public.loi_nhan (
  id uuid primary key default gen_random_uuid(),
  ten text check (char_length(ten) <= 100),
  quan_he text check (char_length(quan_he) <= 100),
  an_danh boolean not null default false,
  ky_niem text,
  dieu_muon_noi text,
  dieu_gin_giu text,
  loi_chuc text,
  hoat_dong text,
  thoi_gian text check (char_length(thoi_gian) <= 100),
  ngay_hen date,
  ghi_chu_hen text,
  loi_nhan_tuong_lai text,
  anh_path text,
  anh_chu_thich text check (char_length(anh_chu_thich) <= 300),
  yeu_thich boolean not null default false,
  tao_luc timestamptz not null default now(),
  check (char_length(coalesce(ky_niem,'') || coalesce(dieu_muon_noi,'') || coalesce(dieu_gin_giu,'')
    || coalesce(loi_chuc,'') || coalesce(hoat_dong,'') || coalesce(ghi_chu_hen,'')
    || coalesce(loi_nhan_tuong_lai,'')) <= 20000)
);

alter table public.loi_nhan enable row level security;

-- Khách chỉ được GỬI lời nhắn mới, không đọc, sửa hay xóa được gì.
drop policy if exists "khach_gui" on public.loi_nhan;
create policy "khach_gui" on public.loi_nhan
  for insert to anon with check (yeu_thich = false);

-- Chỉ chủ nhân (đăng nhập bằng email này) được xem, sửa, xóa tất cả.
drop policy if exists "chu_nhan_toan_quyen" on public.loi_nhan;
create policy "chu_nhan_toan_quyen" on public.loi_nhan
  for all to authenticated
  using ((auth.jwt() ->> 'email') = 'lythnguyenx@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'lythnguyenx@gmail.com');

-- Kho ảnh riêng tư: tối đa 5 MB, chỉ nhận ảnh.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('anh', 'anh', false, 5242880,
  array['image/jpeg','image/png','image/webp','image/heic','image/heif'])
on conflict (id) do nothing;

drop policy if exists "khach_tai_anh" on storage.objects;
create policy "khach_tai_anh" on storage.objects
  for insert to anon with check (bucket_id = 'anh');

drop policy if exists "chu_nhan_anh" on storage.objects;
create policy "chu_nhan_anh" on storage.objects
  for all to authenticated
  using (bucket_id = 'anh' and (auth.jwt() ->> 'email') = 'lythnguyenx@gmail.com')
  with check (bucket_id = 'anh' and (auth.jwt() ->> 'email') = 'lythnguyenx@gmail.com');
