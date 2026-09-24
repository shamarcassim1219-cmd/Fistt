path = 'web/index.html'
content = open(path).read()

# Fix title
content = content.replace(
    '<title>mygame_app</title>',
    '<title>MYGame Marketplace - Buy & Sell Game Accounts Safely</title>'
)

# Fix description meta tag
content = content.replace(
    '<meta name="description" content="A new Flutter project.">',
    '<meta name="description" content="Buy and sell PUBG, Free Fire, CODM and MLBB game accounts safely with secure escrow on MYGame Marketplace.">'
)

open(path, 'w').write(content)
print("SEO TITLE/DESCRIPTION FIXED")
