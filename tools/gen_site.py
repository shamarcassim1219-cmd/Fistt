import json,os
D="https://buysellgame.store"
APK=D+"/downloads/app-release.apk"
WA="https://wa.me/94753536394"
NAV=[("listings.html","Browse accounts"),("sell-game-account-sri-lanka.html","Sell an account"),("tournaments-sri-lanka.html","Tournaments"),("faq.html","FAQ"),("contact.html","Contact"),("https://api.buysellgame.store/","Open web app")]
CSS="""
:root{--ink:#14183a;--gold:#ffb627;--bg:#f2f4f8;--card:#fff;--txt:#23263f;--mut:#5d6280;--line:#dfe2ee}
@media(prefers-color-scheme:dark){:root{--bg:#0e1128;--card:#171b3d;--txt:#eceffc;--mut:#a4a9cc;--line:#2a2f5c}}
*{box-sizing:border-box}html{scroll-behavior:smooth}
body{margin:0;font:17px/1.65 system-ui,-apple-system,Segoe UI,Roboto,sans-serif;background:var(--bg);color:var(--txt)}
h1,h2,h3{font-family:'Bricolage Grotesque',system-ui,sans-serif;line-height:1.15;margin:0 0 .5em}
h1{font-size:clamp(2.1rem,6vw,3.6rem);letter-spacing:-.02em}h2{font-size:clamp(1.5rem,3.5vw,2.1rem)}h3{font-size:1.15rem}
a{color:inherit}.w{max-width:1040px;margin:0 auto;padding:0 20px}
header{background:var(--ink);color:#fff;position:sticky;top:0;z-index:5}
header .w{display:flex;align-items:center;gap:20px;min-height:60px;flex-wrap:wrap}
.logo{display:flex;align-items:center;gap:10px;font:700 1.15rem 'Bricolage Grotesque',sans-serif;text-decoration:none}
.logo img{width:34px;height:34px;border-radius:8px}
nav{display:flex;gap:18px;flex-wrap:wrap;margin-left:auto;font-size:.95rem}nav a{text-decoration:none;opacity:.85;padding:6px 0}nav a:hover,nav a[aria-current]{opacity:1;color:var(--gold)}
.hero{background:var(--ink);color:#fff;padding:64px 0 72px}.hero p{max-width:60ch;font-size:1.15rem;color:#cfd3f2}
.btns{display:flex;gap:12px;flex-wrap:wrap;margin-top:26px}
.b{display:inline-block;padding:13px 22px;border-radius:10px;font-weight:700;text-decoration:none;background:var(--gold);color:#14183a}
.b.o{background:none;color:inherit;border:2px solid currentColor}
main section{padding:52px 0}main p{max-width:70ch}
.g{display:grid;gap:16px;grid-template-columns:repeat(auto-fit,minmax(230px,1fr))}
.c{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:22px}.c h3{margin-bottom:.3em}.c p{margin:0;color:var(--mut);font-size:.97rem}
a.c{text-decoration:none;border-left:5px solid var(--gold)}a.c:hover{border-color:var(--ink)}
ol.s{padding-left:1.2em}ol.s li{margin-bottom:.8em}
details{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px 18px;margin-bottom:10px}summary{cursor:pointer;font-weight:600}details p{margin:.6em 0 0;color:var(--mut)}
.cta{background:var(--gold);color:#14183a;border-radius:18px;padding:34px;margin:20px 0}.cta .b{background:var(--ink);color:#fff}
footer{background:var(--ink);color:#b9bee3;padding:36px 0;font-size:.93rem}footer a{color:#fff;margin-right:16px}
:focus-visible{outline:3px solid var(--gold);outline-offset:2px}
"""
EXTRA="""
:root{--ink:#1a0f3d;--gold:#ffc42e;--v:#7c5cff;--pk:#ff4f9a;--mint:#6ef3c5;--bg:#f5f2ff;--line:#e2dbff;--mut:#5f5a80}
@media(prefers-color-scheme:dark){:root{--bg:#120a2e;--card:#1e1445;--line:#3a2b7a;--mut:#b3aad9}}
header{background:rgba(26,15,61,.92);backdrop-filter:blur(8px)}
.hero{background:radial-gradient(90% 120% at 85% 40%,#4b2fb8 0,#2a1668 45%,#1a0f3d 100%);overflow:hidden}
.hg{display:grid;grid-template-columns:1.2fr .8fr;gap:30px;align-items:center}
.art{position:relative;text-align:center}.art img{max-width:100%;height:auto;filter:drop-shadow(0 20px 40px rgba(0,0,0,.35))}
.fc{position:absolute;background:#fff;color:#1a0f3d;font-weight:700;font-size:.85rem;padding:9px 14px;border-radius:12px;box-shadow:0 8px 24px rgba(0,0,0,.25)}
.f1{top:12%;left:-4%;border-left:5px solid var(--mint)}.f2{bottom:22%;right:-2%;border-left:5px solid var(--pk)}
@media(max-width:760px){.hg{grid-template-columns:1fr}.art{max-width:260px;margin:0 auto}.f1{left:0}.f2{right:0}}
.b{background:var(--gold);box-shadow:0 6px 0 #c48f00;transition:transform .1s}.b:active{transform:translateY(4px);box-shadow:0 2px 0 #c48f00}
.b.o{background:none;box-shadow:none}
.c{border-radius:20px}a.c{border-left:0;border-top:5px solid var(--v)}a.c:nth-child(2n){border-color:var(--pk)}a.c:nth-child(3n){border-color:var(--mint)}
.t{padding:0;overflow:hidden}.t img{width:100%;height:170px;object-fit:cover;display:block}.t h3,.t p{padding:0 20px}.t h3{margin-top:16px}.t p{padding-bottom:20px}
.cta{background:linear-gradient(135deg,#7c5cff,#ff4f9a);color:#fff;border-radius:26px}.cta .b{background:var(--gold);color:#1a0f3d}
"""
CSS+=EXTRA
FAQ=[("How do I buy a game account in Sri Lanka?","Create a BuySellGame account, verify your identity, pick a listing and chat with the seller. Pay from your in-app wallet and confirm once the account is yours. The seller is paid only after you confirm."),
("Is it safe to buy a game account online?","Every seller is identity-verified, payments are held through the wallet until the trade is confirmed, and you can open a dispute if something goes wrong. Our team reviews disputes."),
("How do I sell my game account?","Verify your identity, tap Add listing in the app, add screenshots and a price, and reply to buyers in chat. Once the buyer confirms, the money reaches your wallet and you can withdraw it."),
("Which games can I trade?","Free Fire, PUBG Mobile, Mobile Legends and Call of Duty accounts, plus in-game items and currency."),
("How do tournaments work?","Open the Tournaments tab in the app to see upcoming events, registration windows, start times and results, all in one place."),
("What fees does BuySellGame charge?","A commission is taken on each completed sale and is shown to the seller before they list. See the app for the current rate."),
("What if a trade goes wrong?","Raise a dispute from the trade page. Our team reviews it and, where the buyer is right, the commission on that sale is reversed."),
("Can I use BuySellGame on a browser?","Yes. Browse, buy and manage your account on buysellgame.store, or download the Android APK.")]
def page(fn,title,desc,h1,lead,body,schema=None,app=None):
    nav="".join(f'<a href="{u if u.startswith("http") else "/"+u}"{" aria-current=page" if u==fn else ""}>{t}</a>' for u,t in NAV)
    url=D+("/" if fn=="index.html" else "/"+fn)
    hero=f'<div class="hero" style="padding:34px 0"><div class="w"><h1>{h1}</h1></div></div>' if app else f'<div class="hero"><div class="w hg"><div><h1>{h1}</h1><p>{lead}</p><div class="btns"><a class="b" href="https://api.buysellgame.store/">Open web app</a><a class="b o" href="{APK}">Download Android APK</a></div></div><div class="art"><img src="/img/mascot.png" alt="BuySellGame mascot" width="300" height="364"><div class="fc f1">Verified sellers</div><div class="fc f2">Wallet-protected payment</div></div></div></div>'
    if app: body=f'<section><div class="w"><div id="root" data-view="{app}"></div></div></section>'
    script='<script src="/app.js" defer></script>' if app else ''
    sc=f'<script type="application/ld+json">{json.dumps(schema)}</script>' if schema else ""
    org={"@context":"https://schema.org","@type":"Organization","name":"BuySellGame","url":D+"/","logo":D+"/logo.png","sameAs":["https://www.facebook.com/Mygame.store","https://www.tiktok.com/@Mygame.store","https://t.me/Mygame_store"]}
    return f"""<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title><meta name="description" content="{desc}"><link rel="canonical" href="{url}">
<meta property="og:title" content="{title}"><meta property="og:description" content="{desc}"><meta property="og:url" content="{url}"><meta property="og:image" content="{D}/logo.png"><meta property="og:type" content="website">
<link rel="icon" href="/logo.png"><link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600;12..96,800&display=swap">
<style>{CSS}</style><script type="application/ld+json">{json.dumps(org)}</script>{sc}</head><body>
<header><div class="w"><a class="logo" href="/"><img src="/logo.png" alt="BuySellGame logo" width="34" height="34">BuySellGame</a><nav>{nav}</nav></div></header>
{hero}
<main>{body}</main>{script}
<footer><div class="w"><p><b>BuySellGame</b> is Sri Lanka's marketplace for game accounts and tournaments.</p><p>{"".join(f'<a href="{u if u.startswith("http") else "/"+u}">{t}</a>' for u,t in NAV)}<a href="{WA}">WhatsApp</a><a href="mailto:support@buysell.store">Email</a></p></div></footer></body></html>"""
def sec(inner):return f'<section><div class="w">{inner}</div></section>'
def cta(t="Ready to trade?"):return f'<div class="cta"><h2>{t}</h2><p>Sign up free on the web or Android app. Identity verification keeps every trade accountable.</p><a class="b" href="https://api.buysellgame.store/">Open the web app</a></div>'
faqh=lambda n:"".join(f"<details><summary>{q}</summary><p>{a}</p></details>" for q,a in FAQ[:n])
faqs={"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":q,"acceptedAnswer":{"@type":"Answer","text":a}} for q,a in FAQ]}
games=[("Free Fire","Accounts with rare bundles, high ranks and diamonds."),("PUBG Mobile","Conqueror-tier accounts, skins and UC."),("Mobile Legends","Accounts with skins, heroes and high ranks."),("Call of Duty","COD Mobile accounts and items.")]
import re,urllib.request,html
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)),"..","landing"))
P={}
P["index.html"]=page("index.html","BuySellGame | Buy & Sell Game Accounts in Sri Lanka","Buy and sell Free Fire, PUBG, Mobile Legends and Call of Duty accounts in Sri Lanka. Verified sellers, wallet payments and tournaments.",
"Buy and sell game accounts in Sri Lanka, without the risk.","Free Fire, PUBG Mobile, Mobile Legends and Call of Duty accounts from verified Sri Lankan sellers. Pay through your wallet, chat live and join tournaments.",
sec("<h2>Pick your game</h2><div class='g'>"+"".join(f"<a class='c' href='/listings.html?game={g}'><h3>{g} accounts</h3><p>{d}</p></a>" for g,d in games)+"</div>")
+sec("<h2>More than a marketplace</h2><div class='g'><div class='c t'><img src='/img/tournaments.jpg' alt='Tournament trophy' loading='lazy'><h3>Tournaments</h3><p>Register for Sri Lankan community tournaments and follow prizes and results.</p></div><div class='c t'><img src='/img/ff_info.jpg' alt='Free Fire info checker' loading='lazy'><h3>Free Fire info checker</h3><p>Look up a Free Fire account by UID before you buy.</p></div><div class='c t'><img src='/img/game_tuner.jpg' alt='Game sensitivity tuner' loading='lazy'><h3>Sensitivity tuner</h3><p>Get DPI and sensitivity settings for your game and device.</p></div></div>")+sec("<h2>How a trade works</h2><ol class='s'><li><b>Verify your account.</b> A quick identity check keeps every seller accountable.</li><li><b>Find or list.</b> Browse listings or post your own account, items or currency.</li><li><b>Chat, pay and confirm.</b> Agree details in live chat and pay from your wallet. The seller is paid after you confirm.</li></ol>")
+sec("<h2>Why Sri Lankan gamers use BuySellGame</h2><div class='g'><div class='c'><h3>Verified sellers</h3><p>Sellers pass an identity check before they can list.</p></div><div class='c'><h3>Wallet payments</h3><p>Your money stays protected until the trade is confirmed.</p></div><div class='c'><h3>Dispute support</h3><p>If a trade goes wrong, our team reviews it and helps fix it.</p></div><div class='c'><h3>Sri Lankan tournaments</h3><p>Join community events and track results in the app.</p></div></div>")
+sec("<h2>Common questions</h2>"+faqh(4)+"<p><a href='/faq.html'>Read all questions</a></p>"+cta()),
{"@context":"https://schema.org","@type":"WebSite","name":"BuySellGame","url":D+"/"})
P["buy-game-accounts-sri-lanka.html"]=page("buy-game-accounts-sri-lanka.html","Buy Game Accounts in Sri Lanka | Free Fire, PUBG, ML | BuySellGame","Buy Free Fire, PUBG Mobile, Mobile Legends and Call of Duty accounts in Sri Lanka from verified sellers. Wallet-protected payment and dispute support.",
"Buy game accounts in Sri Lanka safely","Browse accounts from verified sellers, chat before you pay, and only release payment when the account is yours.",
sec("<h2>Accounts you can buy</h2><div class='g'>"+"".join(f"<div class='c'><h3>{g} accounts</h3><p>{d}</p></div>" for g,d in games)+"</div>")
+sec("<h2>How to buy safely</h2><ol class='s'><li>Sign up and verify your identity.</li><li>Open a listing and check screenshots, level and price.</li><li>Message the seller in live chat with any questions.</li><li>Pay from your wallet. Funds are held until you confirm.</li><li>Log in, check the account and confirm. If anything is wrong, open a dispute.</li></ol><h2>What to check before you buy</h2><p>Look at the seller's verified badge, ask for extra screenshots in chat, and never pay outside the app. Trades made through the wallet are the ones our team can protect.</p>"+cta("Find your next account")))
P["sell-game-account-sri-lanka.html"]=page("sell-game-account-sri-lanka.html","Sell Your Game Account in Sri Lanka | BuySellGame","Sell your Free Fire, PUBG, Mobile Legends or COD account in Sri Lanka. Verified buyers, secure wallet payment and withdrawals to your account.",
"Sell your game account in Sri Lanka","List your account in minutes, talk to buyers in chat, and get paid through your wallet.",
sec("<h2>Selling in four steps</h2><ol class='s'><li>Verify your identity once. Buyers trust verified sellers.</li><li>Tap Add listing, choose the game, upload screenshots and set your price.</li><li>Reply to buyers in live chat.</li><li>When the buyer confirms, the money reaches your wallet. Withdraw it when you like.</li></ol><h2>Selling tips</h2><p>Show your rank, level and rare items clearly. Answer quickly and keep the whole trade inside the app so you are covered if a dispute is raised. A commission applies on completed sales and is shown before you list.</p>"+cta("List your first account")))
P["tournaments-sri-lanka.html"]=page("tournaments-sri-lanka.html","Game Tournaments in Sri Lanka | Free Fire & More | BuySellGame","Join Free Fire and mobile game tournaments in Sri Lanka. See registration windows, start times and results in the BuySellGame app.",
"Game tournaments in Sri Lanka","Register for community tournaments and follow results, all inside BuySellGame.",
sec("<h2>How tournaments work</h2><ol class='s'><li>Open the Tournaments tab in the app.</li><li>Check each event's registration window and start time.</li><li>Register before it closes.</li><li>Play, then follow results and prizes in the same place.</li></ol><p>Follow us on <a href='https://www.facebook.com/Mygame.store'>Facebook</a>, <a href='https://www.tiktok.com/@Mygame.store'>TikTok</a> and <a href='https://t.me/Mygame_store'>Telegram</a> for tournament announcements.</p>"+cta("Join the next tournament")))
P["faq.html"]=page("faq.html","FAQ: Buying & Selling Game Accounts in Sri Lanka | BuySellGame","Answers about buying and selling game accounts, wallet payments, fees, disputes and tournaments on BuySellGame.",
"Frequently asked questions","Everything about trading accounts and joining tournaments.",sec(faqh(len(FAQ))+cta()),faqs)
P["contact.html"]=page("contact.html","Contact BuySellGame Support","Contact the BuySellGame team by WhatsApp, email, Telegram, Facebook or TikTok.",
"Contact us","A real person on our team replies.",
sec(f"<div class='g'><a class='c' href='{WA}'><h3>WhatsApp</h3><p>+94 75 353 6394</p></a><a class='c' href='mailto:support@buysell.store'><h3>Email</h3><p>support@buysell.store</p></a><a class='c' href='https://t.me/Mygame_store'><h3>Telegram</h3><p>@Mygame_store</p></a><a class='c' href='https://www.facebook.com/Mygame.store'><h3>Facebook</h3><p>Mygame.store</p></a><a class='c' href='https://www.tiktok.com/@Mygame.store'><h3>TikTok</h3><p>@Mygame.store</p></a></div>"))
for f,t,d,h1,a in [("listings.html","Browse Game Accounts for Sale in Sri Lanka | BuySellGame","Search Free Fire, PUBG, Mobile Legends and more accounts for sale in Sri Lanka.","Game accounts for sale","listings"),("listing.html","Game Account | BuySellGame","Game account for sale on BuySellGame.","Game account","listing"),("login.html","Log in or sign up | BuySellGame","Log in to BuySellGame to buy and sell game accounts.","Your BuySellGame account","login"),("account.html","My account | BuySellGame","Your BuySellGame purchases, sales and wallet.","My account","account")]:
    P[f]=page(f,t,d,h1,"","",app=a)
P["tournaments-sri-lanka.html"]=page("tournaments-sri-lanka.html","Game Tournaments in Sri Lanka | Free Fire & More | BuySellGame","Live list of game tournaments in Sri Lanka with entry fees, prize pools and start times.","Game tournaments in Sri Lanka","",  "",app="tournaments")
def slug(x):return re.sub(r"[^a-z0-9]+","-",x.lower()).strip("-")
try:
    L=json.load(urllib.request.urlopen(urllib.request.Request("https://api.finbassshamar.online/listings",headers={"User-Agent":"Mozilla/5.0"}),timeout=25))["listings"]
except Exception as e:
    print("prerender skipped:",e);L=[]
by={}
for l in L:by.setdefault(l.get("game") or "Other",[]).append(l)
for g,ls in by.items():
    fn=f"buy-{slug(g)}-account-sri-lanka.html"
    items="".join(f"<a class='c' href='/listing.html?id={l['id']}'><h3>{html.escape(str(l.get('title','')))}</h3><p>Rs {int(float(l.get('price') or 0)):,}</p></a>" for l in ls[:60])
    P[fn]=page(fn,f"Buy {g} Accounts in Sri Lanka | BuySellGame",f"{len(ls)} {g} accounts for sale in Sri Lanka from verified sellers.",f"Buy {g} accounts in Sri Lanka","",sec(f"<div class='g'>{items}</div>"+cta()))
for f,h in P.items():open(f,"w").write(h)
open("sitemap.xml","w").write('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'+"".join(f"<url><loc>{D}/{'' if f=='index.html' else f}</loc></url>" for f in P)+"</urlset>")
open("robots.txt","w").write(f"User-agent: *\nAllow: /\n\nSitemap: {D}/sitemap.xml\n")
open(".htaccess","w").write("DirectoryIndex index.html\nOptions -Indexes\n")
