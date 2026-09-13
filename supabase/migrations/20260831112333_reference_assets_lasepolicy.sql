-- reference_assets hade RLS paslaget och noll policies: 82 rader manifest var
-- oatkomliga via REST for samtliga roller. Manifestet ar avsett att vara
-- sokbart underlag, inte hemligt, och det innehaller inga personuppgifter.
-- Las for alla, skrivning enbart via service_role (som gar forbi RLS).
create policy reference_assets_read_all
on public.reference_assets
for select
to public
using (true);
