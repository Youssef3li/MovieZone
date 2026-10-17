import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
export async function POST(request: Request) {
  const sb = await createClient();
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return NextResponse.json({ error: "يجب تسجيل الدخول" }, { status: 401 });
  const body = await request.json().catch(() => ({}));
  if (typeof body.movie_id !== "string") return NextResponse.json({ error: "movie_id مطلوب" }, { status: 400 });
  const { error } = await sb.from("watch_history").upsert({ user_id: user.id, movie_id: body.movie_id, watched_at: new Date().toISOString() }, { onConflict: "user_id,movie_id" });
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ ok: true });
}
