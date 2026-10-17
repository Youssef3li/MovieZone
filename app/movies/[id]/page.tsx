import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
export default async function MoviePage({params}:{params:Promise<{id:string}>}) {
 const {id}=await params;let movie:any=null;
 try{const sb=await createClient();const r=await sb.from("movies").select("*").eq("id",id).eq("published",true).maybeSingle();movie=r.data;}catch{}
 if(!movie)notFound();
 const video=movie.video_url||"";
 return <><header className="topbar"><div className="container nav"><Link href="/" className="brand">سينماك</Link><nav className="navlinks"><Link href="/">الرئيسية</Link><Link href="/profile">حسابي</Link></nav></div></header><main className="container page"><Link href="/">← العودة للرئيسية</Link><div className="details"><aside>{movie.poster_url?<img className="poster" src={movie.poster_url} alt={`بوستر ${movie.title}`}/>:<div className="placeholder">سينماك</div>}</aside><section><div className="eyebrow">{movie.genre||"محتوى مرخّص"}</div><h1>{movie.title}</h1><div className="meta">{movie.release_year||"—"}{movie.rating!==null?` • التقييم ${movie.rating}/10`:""}{movie.duration_minutes?` • ${movie.duration_minutes} دقيقة`:""}</div><h3>القصة</h3><p className="muted">{movie.synopsis||"لا توجد قصة مضافة لهذا العنوان."}</p>{movie.cast_members&&<><h3>طاقم العمل</h3><p className="muted">{movie.cast_members}</p></>}{movie.trailer_url&&<><h3>الإعلان الترويجي</h3><a className="btn secondary" href={movie.trailer_url} target="_blank" rel="noopener noreferrer">مشاهدة الإعلان ↗</a></>}
 <h2>المشاهدة</h2>{video?<video className="video" controls playsInline preload="metadata" poster={movie.poster_url||undefined}><source src={video}/><track kind="captions" srcLang="ar" label="العربية" default src="data:text/vtt,WEBVTT%0A%0A"/>متصفحك لا يدعم تشغيل الفيديو.</video>:<div className="notice">لم يتم إضافة ملف فيديو مرخّص لهذا العنوان بعد.</div>}<p className="small">يجب أن يكون مصدر الفيديو مملوكًا لك أو مرخّصًا، وأن يدعم الاستضافة والنقل إعداداتك.</p></section></div></main></>;
}
