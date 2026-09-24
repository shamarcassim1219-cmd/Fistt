import datetime

def _faq(items):
    return "".join(f"<details><summary>{q}</summary><p>{a}</p></details>" for q, a in items)

def _faq_schema(items):
    return {"@context": "https://schema.org", "@type": "FAQPage", "mainEntity": [
        {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": re.sub("<[^>]+>", "", a)}} for q, a in items]}

_GUIDES = [
    ("buy-free-fire-account-sri-lanka.html", "Buy Free Fire accounts", "Verified sellers, wallet-protected payment."),
    ("free-fire-dpi-sensitivity-settings-sri-lanka.html", "Free Fire DPI and sensitivity settings", "Calculator for every scope."),
    ("free-fire-tournaments-sri-lanka.html", "Free Fire tournaments in Sri Lanka", "Entry fees, prizes and start times."),
    ("buy-game-accounts-sri-lanka.html", "Buy game accounts in Sri Lanka", "Free Fire, PUBG, Mobile Legends and COD."),
    ("sell-game-account-sri-lanka.html", "Sell your game account", "List it and get paid through your wallet."),
]

def _related(cur):
    return "<h2>Related guides</h2><div class='g'>" + "".join(
        f"<a class='c' href='/{u}'><h3>{t}</h3><p>{d}</p></a>" for u, t, d in _GUIDES if u != cur) + "</div>"

def _ff(l):
    return "free fire" in str(l.get("game") or "").lower()

FFL = [l for l in L if _ff(l)]
items = "".join(
    f"<a class='c' href='/listing.html?id={l['id']}'><h3>{html.escape(str(l.get('title', '')))}</h3><p>Rs {int(float(l.get('price') or 0)):,}</p></a>"
    for l in FFL[:60])
live = (f"<h2>Free Fire accounts for sale right now</h2><div class='g'>{items}</div>" if FFL else
        "<h2>Free Fire accounts for sale</h2><p>Open the web app to see the Free Fire accounts that sellers have listed right now, with prices in rupees.</p>")
ffq = [
    ("Is it safe to buy a Free Fire account in Sri Lanka?", "Sellers on BuySellGame are identity-verified and your payment is held in the wallet until you confirm the account is yours. If something is wrong you can open a dispute and our team reviews it. Keep the whole trade inside the app so you are covered."),
    ("How much does a Free Fire account cost in Sri Lanka?", "Sellers set their own prices, based on level, rank, rare bundles, evolved guns and diamonds. Open the listings to compare current prices in Sri Lankan rupees."),
    ("Can I check a Free Fire account before I buy it?", "Yes. Ask the seller for the UID and look it up with the Free Fire info checker in the app, then ask for extra screenshots of the inventory in live chat."),
    ("How do I pay for a Free Fire account?", "You top up your BuySellGame wallet and pay from it. The seller is paid only after you log in, check the account and confirm the trade."),
    ("What if the account has a problem after I buy it?", "Do not confirm the trade. Open a dispute from the trade page and our team will review the chat and the evidence."),
]
P["buy-free-fire-account-sri-lanka.html"] = page(
    "buy-free-fire-account-sri-lanka.html",
    "Buy Free Fire Account in Sri Lanka | BuySellGame",
    "Buy a Free Fire account in Sri Lanka from verified sellers. Check the UID, chat first, pay through the wallet and confirm before the seller is paid.",
    "Buy Free Fire accounts in Sri Lanka",
    "Find Free Fire accounts from verified Sri Lankan sellers, check the UID before you pay, and keep your money protected in the wallet until the account is yours.",
    sec(live)
    + sec("<h2>What to check before you buy a Free Fire account</h2><ul><li><b>Verified seller.</b> Look for the verified badge on the seller's profile.</li><li><b>UID and level.</b> Look the account up with the Free Fire info checker in the app and compare it with the listing.</li><li><b>Inventory.</b> Ask for screenshots of bundles, skins and evolved guns in live chat.</li><li><b>Login method.</b> Ask which account (Facebook, Google and so on) the game is linked to and how it will be handed over.</li><li><b>Payment.</b> Never pay outside the app. Only wallet trades can be protected.</li></ul>")
    + sec("<h2>How to buy a Free Fire account on BuySellGame</h2><ol class='s'><li>Sign up and verify your identity.</li><li>Open a Free Fire listing and check the screenshots, level and price.</li><li>Ask the seller your questions in live chat.</li><li>Pay from your wallet. The money is held until you confirm.</li><li>Log in, check everything and confirm. If it is not as described, open a dispute.</li></ol>")
    + sec("<h2>Free Fire account questions</h2>" + _faq(ffq))
    + sec(_related("buy-free-fire-account-sri-lanka.html") + cta("Find your Free Fire account")),
    _faq_schema(ffq))

def _sens(dpi):
    r = lambda x: max(0, min(200, int(x + 0.5)))
    g = r(50 * 400 / dpi)
    return [g, g, r(g * 1.1), r(g * 1.15), r(g * 1.2), r(g * 1.05)]

rows = "".join("<tr><th>%d</th>%s</tr>" % (d, "".join(f"<td>{v}</td>" for v in _sens(d)))
               for d in (300, 320, 360, 400, 420, 440, 480, 520, 560, 600))
dpiq = [
    ("What is DPI in Free Fire?", "DPI is your phone's screen density, the number of pixels per inch. It decides how far the aim moves when you drag a finger a small distance, so it directly changes how a given sensitivity feels."),
    ("What is the best sensitivity for Free Fire?", "There is no single best value. It depends on your phone's DPI, your grip and your play style. Start from the values in the calculator, then adjust in the training ground."),
    ("Is it safe to change my phone's DPI?", "It is a normal Android display setting, but it makes the whole interface bigger or smaller. Write down the original number first so you can change it back at any time."),
    ("Why do scopes get higher sensitivity?", "Once you zoom in, the same finger movement covers less of the scene, so scopes usually need a slightly higher value to keep the aim easy to control."),
    ("Is this an official Garena tool?", "No. BuySellGame is not affiliated with Garena. Free Fire is a trademark of Garena. The values are a starting point only."),
]
calc = """<style>.tb{width:100%;border-collapse:collapse;font-size:.95rem}.tb th,.tb td{padding:9px 8px;text-align:center;border-bottom:1px solid var(--line)}.tb thead th{color:var(--mut);font-weight:600}.tw{overflow-x:auto}</style>
<div class="c" id="calc"><h3>DPI to sensitivity calculator</h3><p><label for="dpi">Your phone's DPI</label></p>
<p><input id="dpi" type="number" inputmode="numeric" min="100" max="900" value="400" style="padding:12px;border-radius:10px;border:1px solid var(--line);background:var(--card);color:inherit;font:inherit;width:150px"></p>
<div id="out" class="tw"></div></div>
<script>(function(){var m=[["General",1],["Red Dot",1],["2x Scope",1.1],["4x Scope",1.15],["Sniper Scope",1.2],["Free Look",1.05]],i=document.getElementById("dpi"),o=document.getElementById("out");
function c(){var d=parseInt(i.value,10);if(!d||d<100||d>900){o.textContent="Enter a DPI between 100 and 900.";return}
var g=Math.round(50*400/d),h='<table class="tb"><tbody>';m.forEach(function(x){h+="<tr><th>"+x[0]+"</th><td><b>"+Math.max(0,Math.min(200,Math.round(g*x[1])))+"</b></td></tr>"});o.innerHTML=h+"</tbody></table>"}
i.addEventListener("input",c);c()})();</script>"""
P["free-fire-dpi-sensitivity-settings-sri-lanka.html"] = page(
    "free-fire-dpi-sensitivity-settings-sri-lanka.html",
    "Free Fire DPI Settings and Sensitivity Guide | BuySellGame",
    "Find your phone's DPI and get Free Fire sensitivity values for General, Red Dot, 2x, 4x, Sniper and Free Look. Use the calculator or the BuySellGame app.",
    "Free Fire DPI and sensitivity settings",
    "Find your phone's DPI, then use the calculator to get starting sensitivity values for every scope. Fine-tune them in the training ground.",
    sec("<h2>Free Fire sensitivity calculator</h2>" + calc)
    + sec("<h2>Sensitivity by DPI</h2><p>Starting values for common DPIs. A higher DPI moves the aim further for the same swipe, so the sensitivity goes down.</p><div class='tw'><table class='tb'><thead><tr><th>DPI</th><th>General</th><th>Red Dot</th><th>2x</th><th>4x</th><th>Sniper</th><th>Free Look</th></tr></thead><tbody>" + rows + "</tbody></table></div>")
    + sec("<h2>How to find your DPI on Android</h2><ol class='s'><li>Open Settings and go to About phone.</li><li>Tap Build number 7 times to unlock Developer options.</li><li>Go to Settings, Developer options and find Smallest width.</li><li>Note the current number before you change anything. This is the screen density value used here. Some phones also show DPI in their spec sheet or in a device info app.</li></ol><p>The BuySellGame app has a step-by-step Sensitivity tuner that walks you through this and applies the same maths.</p>")
    + sec("<h2>How the values are worked out</h2><p>The calculator starts from a General sensitivity of 50 at 400 DPI and scales it in the opposite direction to your DPI. Red Dot uses the same value, Free Look is 5 percent higher, 2x Scope 10 percent, 4x Scope 15 percent and Sniper Scope 20 percent. Values are limited to 0 to 200.</p><h2>Fine-tuning tips</h2><ul><li>Test in the training ground, not in a ranked match.</li><li>Change one value at a time, in steps of about 5.</li><li>Practise a quick drag from body to head at a target and check that you stop on it.</li><li>Write down the values that work so you can restore them.</li></ul>")
    + sec("<h2>සිංහලෙන්</h2><p lang='si'>ඔබේ දුරකථනයේ DPI අගය Developer options තුළින් සොයාගන්න. DPI වැඩි වන විට Sensitivity අඩු කරන්න, scope වලට තරමක් වැඩි අගයක් දෙන්න. ඉහත calculator එකෙන් ආරම්භක අගයන් ලබාගෙන training ground එකේදී ඔබට ගැලපෙන ලෙස සකසාගන්න.</p>")
    + sec("<h2>DPI and sensitivity questions</h2>" + _faq(dpiq))
    + sec(_related("free-fire-dpi-sensitivity-settings-sri-lanka.html") + cta("Try the Sensitivity tuner in the app")),
    _faq_schema(dpiq))

TZ = datetime.timezone(datetime.timedelta(hours=5, minutes=30))
def _when(ms):
    try:
        return datetime.datetime.fromtimestamp(float(ms) / 1000, TZ).strftime("%d %b %Y, %I:%M %p")
    except Exception:
        return "-"
try:
    _d = json.load(urllib.request.urlopen(urllib.request.Request("https://api.finbassshamar.online/tournaments", headers={"User-Agent": "Mozilla/5.0"}), timeout=25))
    TT = _d.get("tournaments", []) if isinstance(_d, dict) else _d
except Exception as e:
    print("tournaments prerender skipped:", e); TT = []
FT = [t for t in TT if _ff(t)]
def _card(t):
    fee = "Free" if t.get("isFree") else "Rs %s" % f"{int(float(t.get('entryFee') or 0)):,}"
    return ("<div class='c'><h3>%s</h3><p>%s %s Team size %s<br>Entry: %s. Prize pool: Rs %s<br>Registration closes: %s<br>Starts: %s</p></div>" % (
        html.escape(str(t.get("title", ""))), html.escape(str(t.get("game", ""))), html.escape(str(t.get("mode") or "")),
        html.escape(str(t.get("teamSize", "-"))), fee, f"{int(float(t.get('prizePool') or 0)):,}", _when(t.get("regCloseAt")), _when(t.get("startAt"))))
tlive = ("<h2>Free Fire tournaments right now</h2><div class='g'>" + "".join(_card(t) for t in FT[:30]) + "</div><p>Times are Sri Lanka time. Register in the app.</p>" if FT else
         "<h2>Free Fire tournaments right now</h2><p>There are no Free Fire tournaments open at the moment. Open the app to see new events as soon as they are announced.</p>")
tq = [
    ("How do I join a Free Fire tournament in Sri Lanka?", "Open the Tournaments tab in the BuySellGame app, choose an event, check the entry fee, team size and registration window, and register before it closes."),
    ("Are the tournaments free to enter?", "Some events are free and some have an entry fee. Every tournament shows its entry fee, prize pool and start time before you register."),
    ("Can I play solo or do I need a team?", "It depends on the event. The team size is shown on each tournament, for example solo, duo or squad."),
    ("Where can I see the results?", "Results and prizes are shown in the Tournaments tab of the app once an event is finished."),
]
P["free-fire-tournaments-sri-lanka.html"] = page(
    "free-fire-tournaments-sri-lanka.html",
    "Free Fire Tournaments in Sri Lanka | BuySellGame",
    "Join Free Fire tournaments in Sri Lanka. See entry fees, prize pools, registration windows and start times, then register in the BuySellGame app.",
    "Free Fire tournaments in Sri Lanka",
    "See upcoming Free Fire tournaments with entry fees, prize pools and start times, then register and follow the results in the BuySellGame app.",
    sec(tlive)
    + sec("<h2>How Free Fire tournaments work on BuySellGame</h2><ol class='s'><li>Open the Tournaments tab in the app.</li><li>Check the registration window, start time, entry fee and team size.</li><li>Register before registration closes.</li><li>Be online early on match day, then follow the results and prizes in the same place.</li></ol><p>Follow us on <a href='https://www.facebook.com/Mygame.store'>Facebook</a>, <a href='https://www.tiktok.com/@Mygame.store'>TikTok</a> and <a href='https://t.me/Mygame_store'>Telegram</a> for announcements.</p>")
    + sec("<h2>Before you register</h2><ul><li>Check that your squad mates have the game installed and are ready at start time.</li><li>Read the entry fee and prize pool so there are no surprises.</li><li>Set your sensitivity first. Our <a href='/free-fire-dpi-sensitivity-settings-sri-lanka.html'>Free Fire DPI and sensitivity guide</a> gives you a starting point.</li></ul>")
    + sec("<h2>Tournament questions</h2>" + _faq(tq))
    + sec(_related("free-fire-tournaments-sri-lanka.html") + cta("Join the next Free Fire tournament")),
    _faq_schema(tq))

P.pop("buy-garena-free-fire-account-sri-lanka.html", None)
try: os.remove("buy-garena-free-fire-account-sri-lanka.html")
except OSError: pass

P["index.html"] = P["index.html"].replace("</main>",
    "<section><div class='w'><h2>Free Fire in Sri Lanka</h2><div class='g'>" + "".join(
        f"<a class='c' href='/{u}'><h3>{t}</h3><p>{d}</p></a>" for u, t, d in _GUIDES[:3]) + "</div></div></section></main>", 1)

for _f in ("login.html", "account.html", "listing.html"):
    if _f in P:
        P[_f] = P[_f].replace('<meta charset="utf-8">', '<meta charset="utf-8"><meta name="robots" content="noindex,follow">', 1)

for _f in ("index.html", "buy-free-fire-account-sri-lanka.html", "free-fire-dpi-sensitivity-settings-sri-lanka.html",
           "free-fire-tournaments-sri-lanka.html", "login.html", "account.html", "listing.html"):
    open(_f, "w", encoding="utf-8").write(P[_f])

_skip = {"login.html", "account.html", "listing.html"}
open("sitemap.xml", "w", encoding="utf-8").write('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    + "".join(f"<url><loc>{D}/{'' if f == 'index.html' else f}</loc></url>" for f in P if f not in _skip) + "</urlset>")
print("seo pages ready:", len(P), "pages")
