#!/usr/bin/env python3
# Sincronizza le recensioni Google di "Magic by Dash" nel database del sito.
# Chiamate API: 1 per esecuzione (schedulata 1/giorno). Nessun segreto nel codice.
import os, json, urllib.request

PLACE_ID = "ChIJq6rhBqxFwokRIWtohGi16_w"
KEY = os.environ["GOOGLE_PLACES_KEY"]
SB  = os.environ["SUPABASE_URL"].rstrip("/")
SEC = os.environ["SUPABASE_SERVICE_KEY"]
MARK = "__google_sync__"   # marcatore invisibile: distingue le recensioni Google da quelle dei clienti

def gget(url, headers):
    return json.load(urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=30))

def sb(method, path, body=None, extra=None):
    h = {"apikey": SEC, "Authorization": "Bearer "+SEC, "Content-Type": "application/json"}
    if extra: h.update(extra)
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.urlopen(urllib.request.Request(SB+"/rest/v1/"+path, data=data, headers=h, method=method), timeout=30)
    t = r.read().decode()
    return json.loads(t) if t.strip() else None

# 1) Google Places (New) - 1 chiamata
det = gget("https://places.googleapis.com/v1/places/"+PLACE_ID,
           {"X-Goog-Api-Key": KEY,
            "X-Goog-FieldMask": "displayName,rating,userRatingCount,reviews"})
rating = det.get("rating"); count = det.get("userRatingCount")
revs = det.get("reviews", [])
print(f"Google: {rating}* / {count} recensioni / {len(revs)} estratte")

# 2) Costruisci le righe PRIMA di toccare il DB
rows = []
for i, r in enumerate(revs):
    au  = (r.get("authorAttribution", {}).get("displayName") or "").strip() or "Google user"
    txt = ((r.get("text") or r.get("originalText") or {}).get("text") or "").strip()
    if not txt: continue
    rows.append({"author": au, "text": txt, "stars": int(round(r.get("rating", 5))),
                 "role": "", "email": MARK, "approved": True, "position": 10+i})

# 3) SICUREZZA: se l'API non ha dato recensioni, NON cancellare nulla (evita di svuotare il sito)
if not rows:
    print("Nessuna recensione dall'API: lascio il DB invariato ed esco.")
    raise SystemExit(0)

# 4) sostituisci solo le recensioni marcate Google (le manuali dei clienti restano intatte)
sb("DELETE", "bushi_reviews?email=eq."+MARK)
sb("POST", "bushi_reviews", rows, {"Prefer": "return=minimal"})
print(f"Aggiornate {len(rows)} recensioni Google.")

# 5) rating/conteggio/link per l'intestazione del sito (upsert)
# Link = pagina/scheda Google di Dash (knowledge panel, mostra rating e recensioni),
# non l'app Maps. e' il link ufficiale del suo profilo (anche sul biglietto da visita).
place_url = "https://g.co/kgs/jyDp8wc"
for k, v in [("google_rating", str(rating)), ("google_review_count", str(count)), ("google_place_url", place_url)]:
    sb("POST", "bushi_settings?on_conflict=key", [{"key": k, "value": v}],
       {"Prefer": "resolution=merge-duplicates,return=minimal"})
print("Settings aggiornate.")
