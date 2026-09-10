class GamesList {
  static const List<String> games = [
    'PUBG Mobile', 'Free Fire', 'Call of Duty Mobile', 'Mobile Legends: Bang Bang',
    'Genshin Impact', 'Clash of Clans', 'Clash Royale', 'Fortnite', 'Valorant',
    'League of Legends', 'League of Legends: Wild Rift', 'Brawl Stars', 'Roblox',
    'Minecraft', 'Among Us', 'Apex Legends Mobile', 'Arena of Valor', 'Asphalt 9',
    'Candy Crush Saga', 'Coin Master', 'FIFA Mobile',
    'Garena Free Fire', 'Honkai Star Rail', 'Honor of Kings',
    'Lords Mobile', 'Marvel Snap',
    'Modern Combat 5', 'Pokémon GO', 'Rise of Kingdoms', 'Rocket League',
    'Standoff 2', 'State of Survival', 'Stumble Guys', 'Subway Surfers', 'Summoners War',
    'Teamfight Tactics', 'Tower of Fantasy', 'World of Tanks Blitz', 'Zombie Survival',
    'Dota 2', 'Counter-Strike 2', 'GTA V', 'GTA Online', 'Red Dead Redemption 2',
    'Minecraft Java', 'Minecraft Bedrock', 'Terraria', 'Rust', 'ARK: Survival Evolved',
    'Overwatch 2', 'Warzone', 'Modern Warfare', 'Black Ops', 'Battlefield',
    'FIFA 24', 'eFootball', 'NBA 2K', 'Madden NFL',
    'World of Warcraft', 'Final Fantasy XIV', 'Lost Ark', 'New World', 'Elder Scrolls Online',
    'Diablo Immortal', 'Diablo IV', 'Path of Exile', 'Destiny 2', 'Warframe',
    'Fall Guys', 'Roblox', 'Grounded', 'Valheim', 'Sea of Thieves',
    'Fire Emblem Heroes', 'AFK Arena', 'Raid: Shadow Legends', 'Star Wars Galaxy of Heroes',
    'Marvel Contest of Champions', 'DC Legends', 'Injustice 2 Mobile', 'Mortal Kombat Mobile',
    'Real Racing 3', 'Asphalt 8', 'CarX Street', 'Need for Speed No Limits',
    'Township', 'Hay Day', 'Farmville', 'Homescapes', 'Gardenscapes',
    'Dragon City', 'Monster Legends', 'Empires & Puzzles', 'Guardian Tales',
    'Epic Seven', 'Seven Deadly Sins', 'One Piece Bounty Rush', 'Naruto Blazing',
    'Dragon Ball Legends', 'My Hero Academia: The Strongest Hero', 'Bleach: Brave Souls',
    'Wild Rift', 'Identity V', 'Ragnarok Origin', 'Lineage 2M', 'Black Desert Mobile',
    'Rise of Empires', 'Age of Origins', 'Puzzles & Survival', 'Last Shelter: Survival',
    'World War Heroes', 'Modern Ops', 'Sniper 3D', 'Cover Fire',
    'Other',
  ];

  // Category assigned per game. Used to suggest relevant stat fields.
  static const Map<String, String> gameCategory = {
    'PUBG Mobile': 'shooter', 'Free Fire': 'shooter', 'Garena Free Fire': 'shooter',
    'Call of Duty Mobile': 'shooter', 'Fortnite': 'shooter', 'Valorant': 'shooter',
    'Apex Legends Mobile': 'shooter', 'Counter-Strike 2': 'shooter', 'Warzone': 'shooter',
    'Modern Warfare': 'shooter', 'Black Ops': 'shooter', 'Battlefield': 'shooter',
    'Standoff 2': 'shooter', 'World War Heroes': 'shooter', 'Modern Ops': 'shooter',
    'Sniper 3D': 'shooter', 'Cover Fire': 'shooter', 'Modern Combat 5': 'shooter',
    'Destiny 2': 'shooter', 'Overwatch 2': 'shooter',

    'Mobile Legends: Bang Bang': 'moba', 'League of Legends': 'moba',
    'League of Legends: Wild Rift': 'moba', 'Wild Rift': 'moba', 'Arena of Valor': 'moba',
    'Dota 2': 'moba', 'Honor of Kings': 'moba', 'Teamfight Tactics': 'moba',

    'Clash of Clans': 'strategy', 'Clash Royale': 'strategy', 'Rise of Kingdoms': 'strategy',
    'Lords Mobile': 'strategy', 'State of Survival': 'strategy', 'Rise of Empires': 'strategy',
    'Age of Origins': 'strategy', 'Puzzles & Survival': 'strategy', 'Last Shelter: Survival': 'strategy',
    'Township': 'strategy', 'Hay Day': 'strategy', 'Farmville': 'strategy',

    'Genshin Impact': 'rpg', 'Honkai Star Rail': 'rpg', 'Tower of Fantasy': 'rpg',
    'World of Warcraft': 'rpg', 'Final Fantasy XIV': 'rpg', 'Lost Ark': 'rpg',
    'New World': 'rpg', 'Elder Scrolls Online': 'rpg', 'Diablo Immortal': 'rpg',
    'Diablo IV': 'rpg', 'Path of Exile': 'rpg', 'Warframe': 'rpg',
    'AFK Arena': 'rpg', 'Raid: Shadow Legends': 'rpg', 'Epic Seven': 'rpg',
    'Seven Deadly Sins': 'rpg', 'Summoners War': 'rpg', 'Guardian Tales': 'rpg',
    'Ragnarok Origin': 'rpg', 'Lineage 2M': 'rpg', 'Black Desert Mobile': 'rpg',
    'Dragon Ball Legends': 'rpg', 'Bleach: Brave Souls': 'rpg', 'Naruto Blazing': 'rpg',
    'One Piece Bounty Rush': 'rpg', 'Star Wars Galaxy of Heroes': 'rpg',
    'Marvel Contest of Champions': 'rpg', 'Mortal Kombat Mobile': 'rpg', 'Injustice 2 Mobile': 'rpg',
    'DC Legends': 'rpg', 'Fire Emblem Heroes': 'rpg', 'My Hero Academia: The Strongest Hero': 'rpg',
  };

  static const Map<String, List<String>> categoryStats = {
    'shooter': ['Level', 'Rank', 'Skins/Items', 'In-Game Currency'],
    'moba': ['Rank', 'Heroes/Champions', 'Skins', 'Win Rate'],
    'strategy': ['Town Hall / HQ Level', 'Trophies', 'Heroes Level', 'Base Rating'],
    'rpg': ['Adventure Rank / Level', 'Characters/Heroes', 'World Level', 'Gear Score'],
    'other': ['Level', 'Rank', 'Items/Currency'],
  };

  static String categoryFor(String game) => gameCategory[game] ?? 'other';
  static List<String> suggestedStatsFor(String game) => categoryStats[categoryFor(game)]!;
}
