/**
 * Seed script: ports the Flutter prototype's mock world (lib/data/mock_data.dart)
 * into PostgreSQL so the API serves the same content the app shows.
 *
 * Dates are generated relative to "now" so the feed always looks alive.
 * Re-runnable: truncates everything before inserting.
 */
import { pool } from './db.js';

const DINNER = 'assets/images/dinners';
const VENUE = 'assets/images/restaurants';
const PEOPLE = 'assets/images/people';

const img = {
  longTable: `${DINNER}/long_table.jpg`,
  omakase: `${DINNER}/omakase.jpg`,
  rooftop: `${DINNER}/rooftop.jpg`,
  trattoria: `${DINNER}/trattoria.jpg`,
  wineTasting: `${DINNER}/wine_tasting.jpg`,
  fireFeast: `${DINNER}/fire_feast.jpg`,
  dessertTasting: `${DINNER}/dessert_tasting.jpg`,
  supperClub: `${DINNER}/supper_club.jpg`,
  izakaya: `${VENUE}/izakaya.jpg`,
  bistro: `${VENUE}/bistro.jpg`,
  gardenTerrace: `${VENUE}/garden_terrace.jpg`,
  wineCellar: `${VENUE}/wine_cellar.jpg`,
  farmKitchen: `${VENUE}/farm_kitchen.jpg`,
  nora: `${PEOPLE}/nora.jpg`,
  ava: `${PEOPLE}/ava.jpg`,
  marco: `${PEOPLE}/marco.jpg`,
  yuki: `${PEOPLE}/yuki.jpg`,
};

/** Wall-clock moment `dayOffset` days from today at hour:minute local time. */
function at(dayOffset: number, hour: number, minute = 0): Date {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  today.setDate(today.getDate() + dayOffset);
  today.setHours(hour, minute, 0, 0);
  return today;
}

// ── Users ────────────────────────────────────────────────────────────────────

const users = [
  {
    id: 'u_me', name: 'Nora Bennett', handle: 'nora.b', phone: '+351910000001', city: 'Lisbon',
    bio: 'Marketing lead who plans her week around food. Hosting small tables in Chiado.',
    followers: 1284, following: 312, dinnersHosted: 3, dinnersJoined: 24,
    rating: 4.93, reviewCount: 41, avatarAsset: img.nora,
    badges: ['verified', 'host'], tastes: ['Natural wine', 'Japanese', 'Vegetarian'],
    joinedYear: 2023,
  },
  {
    id: 'u_ava', name: 'Ava Moretti', handle: 'ava.moretti', phone: '+351910000002', city: 'Lisbon',
    bio: 'Chef. 12 years in Japanese kitchens. I build tasting counters for eight strangers at a time.',
    followers: 48200, following: 214, dinnersHosted: 68, dinnersJoined: 39,
    rating: 4.98, reviewCount: 611, avatarAsset: img.ava,
    badges: ['verified', 'influencer', 'host'], tastes: ['Omakase', 'Fermentation', 'Sake'],
    joinedYear: 2022,
  },
  {
    id: 'u_marco', name: 'Marco Ferreira', handle: 'marco.pours', phone: '+351910000003', city: 'Lisbon',
    bio: 'Sommelier at The Vault. I open bottles you will not find by the glass.',
    followers: 21400, following: 189, dinnersHosted: 41, dinnersJoined: 52,
    rating: 4.96, reviewCount: 388, avatarAsset: img.marco,
    badges: ['verified', 'host'], tastes: ['Old world wine', 'Cheese', 'Offal'],
    joinedYear: 2022,
  },
  {
    id: 'u_yuki', name: 'Yuki Tanaka', handle: 'yuki.bites', phone: '+351910000004', city: 'Lisbon',
    bio: 'Food films and long tables. I host sunset dinners so people actually talk to each other.',
    followers: 127000, following: 402, dinnersHosted: 96, dinnersJoined: 118,
    rating: 4.91, reviewCount: 1420, avatarAsset: img.yuki,
    badges: ['verified', 'influencer', 'host'], tastes: ['Seafood', 'Sake', 'Dessert'],
    joinedYear: 2021,
  },
  {
    id: 'u_leo', name: 'Léo Martins', handle: 'leo.fire', phone: '+351910000005', city: 'Lisbon',
    bio: 'Live-fire cooking, farm produce, no plates that need cutlery.',
    followers: 8940, following: 233, dinnersHosted: 27, dinnersJoined: 44,
    rating: 4.88, reviewCount: 204, avatarAsset: null,
    badges: ['verified', 'host', 'risingHost'], tastes: ['Grill', 'Sourdough', 'Cider'],
    accentHex: '#2E4B3C', joinedYear: 2023,
  },
  {
    id: 'u_amara', name: 'Amara Silva', handle: 'amara.patisserie', phone: '+351910000006', city: 'Lisbon',
    bio: 'Pastry chef. Teaching people to temper chocolate without fear.',
    followers: 15600, following: 301, dinnersHosted: 19, dinnersJoined: 31,
    rating: 4.94, reviewCount: 176, avatarAsset: null,
    badges: ['verified', 'host'], tastes: ['Viennoiserie', 'Chocolate', 'Coffee'],
    accentHex: '#7A4A2E', joinedYear: 2023,
  },
  {
    id: 'u_tomas', name: 'Tomás Oliveira', handle: 'tomas.o', phone: '+351910000007', city: 'Lisbon',
    bio: 'Sunday lunches that run until 6 pm. Bring an appetite and no plans.',
    followers: 6120, following: 158, dinnersHosted: 34, dinnersJoined: 60,
    rating: 4.85, reviewCount: 289, avatarAsset: null,
    badges: ['host'], tastes: ['Roasts', 'Pet-nat', 'Long lunches'],
    accentHex: '#3A5A72', joinedYear: 2022,
  },
  {
    id: 'u_sofia', name: 'Sofia Duarte', handle: 'sofia.uncorked', phone: '+351910000008', city: 'Lisbon',
    bio: 'Wine educator. My tables are for people who want to ask the wine questions out loud.',
    followers: 10800, following: 276, dinnersHosted: 22, dinnersJoined: 48,
    rating: 4.9, reviewCount: 231, avatarAsset: null,
    badges: ['verified', 'host'], tastes: ['Biodynamic', 'Sparkling', 'Fortified'],
    accentHex: '#6A3A5E', joinedYear: 2023,
  },
  // Guests who fill out attendee stacks and reviews.
  { id: 'u_ines', name: 'Inês Rocha', handle: 'ines.r', city: 'Lisbon', bio: 'Photographer, always hungry.', followers: 2310, following: 410, dinnersHosted: 0, dinnersJoined: 18, rating: 4.8, reviewCount: 12, avatarAsset: null, badges: [], tastes: [], accentHex: '#B5502E', joinedYear: 2024 },
  { id: 'u_diego', name: 'Diego Costa', handle: 'diego.c', city: 'Porto', bio: 'Cheese, mostly.', followers: 890, following: 220, dinnersHosted: 1, dinnersJoined: 26, rating: 4.7, reviewCount: 9, avatarAsset: null, badges: [], tastes: [], accentHex: '#2F5A6E', joinedYear: 2024 },
  { id: 'u_priya', name: 'Priya Nair', handle: 'priya.n', city: 'Lisbon', bio: 'Chasing the best vegetarian tables in the city.', followers: 3450, following: 612, dinnersHosted: 0, dinnersJoined: 33, rating: 4.9, reviewCount: 21, avatarAsset: null, badges: [], tastes: [], accentHex: '#7A5A22', joinedYear: 2024 },
  { id: 'u_hugo', name: 'Hugo Lindqvist', handle: 'hugo.l', city: 'Lisbon', bio: 'Here for the wine lists.', followers: 1420, following: 288, dinnersHosted: 0, dinnersJoined: 14, rating: 4.6, reviewCount: 7, avatarAsset: null, badges: [], tastes: [], accentHex: '#3E5A3A', joinedYear: 2024 },
  { id: 'u_maple', name: 'Maple Chen', handle: 'maple.c', city: 'Lisbon', bio: 'Baker. I will bring pastry.', followers: 5120, following: 340, dinnersHosted: 2, dinnersJoined: 29, rating: 4.85, reviewCount: 16, avatarAsset: null, badges: [], tastes: [], accentHex: '#8A4A6A', joinedYear: 2024 },
  { id: 'u_jonas', name: 'Jonas Weber', handle: 'jonas.w', city: 'Lisbon', bio: 'New in town. Show me your favourite counter.', followers: 640, following: 122, dinnersHosted: 0, dinnersJoined: 6, rating: 4.5, reviewCount: 3, avatarAsset: null, badges: [], tastes: [], accentHex: '#4A4A7A', joinedYear: 2024 },
  { id: 'u_reem', name: 'Reem Haddad', handle: 'reem.h', city: 'Lisbon', bio: 'Cookbook collector and very slow eater.', followers: 2980, following: 501, dinnersHosted: 1, dinnersJoined: 22, rating: 4.88, reviewCount: 11, avatarAsset: null, badges: [], tastes: [], accentHex: '#9A5222', joinedYear: 2024 },
  { id: 'u_kai', name: 'Kai Andersen', handle: 'kai.a', city: 'Lisbon', bio: 'Sourdough, ferments, long walks home.', followers: 1760, following: 264, dinnersHosted: 0, dinnersJoined: 17, rating: 4.75, reviewCount: 8, avatarAsset: null, badges: [], tastes: [], accentHex: '#2A6A5A', joinedYear: 2024 },
];

// The signed-in user follows Ava and Yuki, mirroring AppState defaults.
const follows: Array<[follower: string, followee: string]> = [
  ['u_me', 'u_ava'],
  ['u_me', 'u_yuki'],
];

// ── Restaurants ──────────────────────────────────────────────────────────────

const restaurants = [
  {
    id: 'r_izakaya', name: 'Kōan Izakaya', cuisine: 'Japanese', neighborhood: 'Cais do Sodré',
    address: 'Rua da Boavista 112', rating: 4.8, reviewCount: 412, priceLevel: 2,
    distanceMeters: 850, heroAsset: img.izakaya,
    description: 'A twelve-seat counter behind an unmarked door. Binchotan grill, house sake and a menu that changes with the market.',
    gallery: [img.izakaya, img.omakase, img.longTable],
    tags: ['Counter seating', 'Late night', 'Sake list'],
    isPartner: true, partnerPerk: 'Complimentary sake flight for every DineCircle table',
    openingHours: 'Wed – Sun · 6 pm – 1 am', seatsAvailable: 24,
  },
  {
    id: 'r_bistro', name: 'Maison Lumen', cuisine: 'Modern European', neighborhood: 'Chiado',
    address: 'Rua Garrett 42', rating: 4.7, reviewCount: 268, priceLevel: 3,
    distanceMeters: 1600, heroAsset: img.bistro,
    description: 'Marble bar, brass rails and a short menu built around one wood oven. The room is brightest at lunch and warmest after nine.',
    gallery: [img.bistro, img.trattoria, img.dessertTasting],
    tags: ['Wood oven', 'Bar seating', 'Vegetarian menu'],
    isPartner: true, partnerPerk: '20% off the à la carte wine list',
    openingHours: 'Tue – Sun · 12 pm – 12 am', seatsAvailable: 18,
  },
  {
    id: 'r_terrace', name: 'Terrazza Nove', cuisine: 'Mediterranean', neighborhood: 'Príncipe Real',
    address: 'Rua da Escola Politécnica 88', rating: 4.6, reviewCount: 331, priceLevel: 3,
    distanceMeters: 3100, heroAsset: img.gardenTerrace,
    description: 'A vine-covered terrace above the city. Long tables, small plates, and a sunset that does most of the work.',
    gallery: [img.gardenTerrace, img.rooftop, img.longTable],
    tags: ['Terrace', 'Sharing plates', 'Sunset'],
    isPartner: true, partnerPerk: 'A welcome spritz for every guest at your table',
    openingHours: 'Tue – Sun · 12 pm – 11 pm', seatsAvailable: 40,
  },
  {
    id: 'r_cellar', name: 'The Vault', cuisine: 'Wine bar & kitchen', neighborhood: 'Alfama',
    address: 'Rua de São Pedro 9', rating: 4.9, reviewCount: 187, priceLevel: 4,
    distanceMeters: 2200, heroAsset: img.wineCellar,
    description: 'A vaulted brick cellar holding 4,000 bottles. Twelve seats, one long walnut table, and no music after the first pour.',
    gallery: [img.wineCellar, img.wineTasting, img.supperClub],
    tags: ['Cellar', 'Rare bottles', 'Tasting menu'],
    isPartner: true, partnerPerk: 'Private cellar tour for tables of six or more',
    openingHours: 'Thu – Sun · 7 pm – 12 am', seatsAvailable: 12,
  },
  {
    id: 'r_farm', name: 'Root & Ember', cuisine: 'Farm-to-table', neighborhood: 'Belém',
    address: 'Rua de Belém 156', rating: 4.7, reviewCount: 502, priceLevel: 2,
    distanceMeters: 4400, heroAsset: img.farmKitchen,
    description: 'An open kitchen attached to a working farm an hour outside the city. Everything on the table was harvested within a day.',
    gallery: [img.farmKitchen, img.fireFeast, img.longTable],
    tags: ['Open kitchen', 'Farm produce', 'Outdoor tables'],
    isPartner: false, partnerPerk: null,
    openingHours: 'Fri – Sun · 12 pm – 10 pm', seatsAvailable: 30,
  },
];

// ── Dinner events (with menus) ───────────────────────────────────────────────

interface MenuItemSeed { name: string; description: string; pairing?: string; isSignature?: boolean }

interface EventSeed {
  id: string; title: string; tagline: string; description: string;
  hostId: string; restaurantId: string; imageAsset: string; gallery: string[];
  start: Date; durationMinutes: number; seatsTotal: number; seatsTaken: number;
  pricePerSeat: number; type: string; audience: string; menuStyle: string;
  included: string[]; tags: string[]; isFeatured?: boolean; hostNote?: string;
  language?: string; dressCode?: string; cancellation?: string; attendeeIds: string[];
  menu: MenuItemSeed[];
}

const events: EventSeed[] = [
  {
    id: 'e1', title: "Chef's Counter Omakase",
    tagline: 'Eight seats, fourteen courses, one chef talking you through every piece.',
    description: 'We take over the whole counter for the evening. Ava cooks in front of you and plates each course by hand — expect aged fish, house-cured roe and a sake poured for every third course. Come alone or come with one person; the counter is built for conversation.',
    hostId: 'u_ava', restaurantId: 'r_izakaya', imageAsset: img.omakase,
    gallery: [img.omakase, img.izakaya, img.wineTasting],
    start: at(2, 19, 30), durationMinutes: 165, seatsTotal: 8, seatsTaken: 6,
    pricePerSeat: 95, type: 'tasting', audience: 'public', menuStyle: 'tastingMenu',
    included: ['14-course omakase menu', 'Three sake pairings', 'Counter seat with the chef', 'Service and taxes'],
    tags: ['Counter', 'Sake pairing', 'Small group', 'Seafood'],
    language: 'English', dressCode: 'Come as you are', isFeatured: true,
    hostNote: 'Tell me in the chat if you do not eat something — I shop for the counter on the morning of the dinner.',
    attendeeIds: ['u_me', 'u_ines', 'u_diego', 'u_priya', 'u_maple', 'u_kai'],
    menu: [
      { name: 'Aged kinmedai, yuzu kosho', description: 'Dry-aged five days, thin-sliced over warm rice.', isSignature: true },
      { name: 'Binchotan-grilled eel', description: 'Glazed with house tare, finished over white charcoal.', pairing: 'Junmai daiginjo' },
      { name: 'House-cured roe donabe', description: 'Clay-pot rice, ikura cured in-house that afternoon.' },
      { name: 'Miso caramel mochi', description: 'Warm mochi, white miso caramel, toasted soy powder.', pairing: 'Barley shochu' },
    ],
  },
  {
    id: 'e2', title: 'Sunset Table on the Terrace',
    tagline: 'Fourteen strangers, one long table, and the best light of the day.',
    description: 'We start with a spritz on the terrace while the sun drops behind the hill, then sit for a shared Mediterranean menu. Phones go face-down during the first course — after that, do whatever you like.',
    hostId: 'u_yuki', restaurantId: 'r_terrace', imageAsset: img.rooftop,
    gallery: [img.rooftop, img.gardenTerrace, img.longTable],
    start: at(1, 20), durationMinutes: 180, seatsTotal: 14, seatsTaken: 11,
    pricePerSeat: 62, type: 'dinner', audience: 'public', menuStyle: 'familyStyle',
    included: ['Welcome spritz', 'Seven shared plates', 'One dessert', 'Terrace seat at sunset'],
    tags: ['Terrace', 'Sunset', 'New people', 'Vegetarian friendly'],
    isFeatured: true,
    hostNote: 'There is a short walk up to the terrace — message me if you need the step-free route.',
    attendeeIds: ['u_ines', 'u_diego', 'u_priya', 'u_hugo', 'u_maple', 'u_jonas', 'u_reem', 'u_kai'],
    cancellation: 'Free cancellation up to 24 hours before',
    menu: [
      { name: 'Grilled octopus, smoked paprika', description: 'Charred over vine cuttings.' },
      { name: 'Tomato and almond salmorejo', description: 'Chilled, finished with aged sherry vinegar.', isSignature: true },
      { name: 'Charcoal lamb shoulder', description: 'Six hours over embers, carved at the table.' },
      { name: 'Fig leaf ice cream', description: 'Infused for two days, served with honeycomb.' },
    ],
  },
  {
    id: 'e3', title: 'Handmade Pasta Night',
    tagline: 'Roll, cut and eat three shapes of pasta in one evening.',
    description: 'We start at the pass with flour and eggs, then move to the table for the eating part. Marco opens a bottle of something Italian and unfussy to go with it.',
    hostId: 'u_marco', restaurantId: 'r_bistro', imageAsset: img.trattoria,
    gallery: [img.trattoria, img.bistro, img.dessertTasting],
    start: at(4, 19), durationMinutes: 150, seatsTotal: 12, seatsTaken: 7,
    pricePerSeat: 54, type: 'dinner', audience: 'public', menuStyle: 'familyStyle',
    included: ['Hands-on pasta session', 'Three-course dinner', 'Glass of wine', 'Recipe cards'],
    tags: ['Hands-on', 'Beginner friendly', 'Vegetarian friendly'],
    hostNote: 'Aprons are provided. Wear something you do not mind dusting with flour.',
    attendeeIds: ['u_hugo', 'u_priya', 'u_jonas', 'u_kai'],
    menu: [
      { name: 'Tagliatelle, butter and parmesan', description: 'The one to learn by heart.' },
      { name: 'Cacio e pepe ravioli', description: 'Filled with pecorino cream, cracked pepper.' },
      { name: 'Torta della nonna', description: 'Pine nut tart, lemon zest, cold cream.', isSignature: true },
    ],
  },
  {
    id: 'e4', title: 'Rare Vintages in the Cellar',
    tagline: 'Five pours from the back of the cellar that never make it to the list.',
    description: 'A tasting for people who already like wine and want to go deeper. Marco pulls bottles from the private racks — older Douro, a Jura white, and one bottle we will not name until you taste it.',
    hostId: 'u_marco', restaurantId: 'r_cellar', imageAsset: img.wineTasting,
    gallery: [img.wineTasting, img.wineCellar, img.supperClub],
    start: at(6, 19, 30), durationMinutes: 150, seatsTotal: 10, seatsTaken: 8,
    pricePerSeat: 120, type: 'tasting', audience: 'followers', menuStyle: 'tastingMenu',
    included: ['Five rare pours', 'Cheese and charcuterie board', 'Cellar tour', 'Tasting notes'],
    tags: ['Wine', 'Cellar', 'Small group'],
    language: 'English & Portuguese',
    hostNote: 'This one is aimed at followers who have been asking for an advanced tasting. No prior study needed.',
    attendeeIds: ['u_me', 'u_sofia', 'u_hugo', 'u_reem', 'u_ines', 'u_diego', 'u_kai', 'u_maple'],
    cancellation: 'Free cancellation up to 72 hours before',
    menu: [
      { name: 'Aged Douro red', description: 'Twenty years in bottle, decanted an hour before.' },
      { name: 'Jura savagnin', description: 'Oxidative, salty, unmistakable.', pairing: 'Comté 24 months', isSignature: true },
      { name: 'Vintage port', description: 'Served with toasted almonds and blue cheese.' },
    ],
  },
  {
    id: 'e5', title: 'Ember & Smoke',
    tagline: 'Everything cooked over fire, eaten outdoors at a long trestle table.',
    description: 'Léo lights the fire at four and cooks on it for three hours. Flatbreads, charred vegetables, a whole fish and a shoulder of pork, all served family style as it comes off the grill.',
    hostId: 'u_leo', restaurantId: 'r_farm', imageAsset: img.fireFeast,
    gallery: [img.fireFeast, img.farmKitchen, img.longTable],
    start: at(3, 18, 30), durationMinutes: 210, seatsTotal: 16, seatsTaken: 9,
    pricePerSeat: 58, type: 'dinner', audience: 'public', menuStyle: 'sharing',
    included: ['Fire-cooked menu', 'Cider on arrival', 'Outdoor table', 'Farm tour'],
    tags: ['Outdoor', 'Fire cooking', 'Family style', 'Vegetarian friendly'],
    dressCode: 'Layers — it cools down after sunset',
    hostNote: 'It is a fifteen-minute walk from the tram stop through the farm gate. I will send directions the day before.',
    attendeeIds: ['u_tomas', 'u_ines', 'u_priya', 'u_jonas', 'u_reem'],
    menu: [
      { name: 'Ember-roasted flatbread', description: 'Baked against the coals, olive oil and salt.' },
      { name: 'Whole fish in fig leaves', description: 'Brought in that morning.', isSignature: true },
      { name: 'Charred greens, romesco', description: 'Whatever came out of the field.' },
      { name: 'Burnt honey tart', description: 'Baked in the residual heat of the fire.' },
    ],
  },
  {
    id: 'e6', title: 'Pastry Atelier: Behind the Pass',
    tagline: 'Temper chocolate, laminate dough, and take home a box.',
    description: 'A three-hour workshop for twelve people in a working pastry kitchen, followed by tea and everything you made. Amara runs it hands-on — you will be at a bench, not in a chair.',
    hostId: 'u_amara', restaurantId: 'r_bistro', imageAsset: img.dessertTasting,
    gallery: [img.dessertTasting, img.bistro, img.trattoria],
    start: at(9, 16), durationMinutes: 180, seatsTotal: 10, seatsTaken: 4,
    pricePerSeat: 72, type: 'workshop', audience: 'public', menuStyle: 'setMenu',
    included: ['All ingredients and tools', 'Box of pastries to take home', 'Tea and coffee', 'Recipe booklet'],
    tags: ['Hands-on', 'Beginner friendly', 'Take home'],
    hostNote: 'Bring a container if you want to take more than the box holds. People always do.',
    attendeeIds: ['u_priya', 'u_maple', 'u_reem'],
    cancellation: 'Free cancellation up to 7 days before',
    menu: [
      { name: 'Chocolate tempering', description: 'The science, then a tempered bar of your own.' },
      { name: 'Laminated dough', description: 'Two turns by hand, baked before you leave.' },
      { name: 'Berry pavlova', description: 'Built and eaten on site.', isSignature: true },
    ],
  },
  {
    id: 'e7', title: 'Midnight Supper Club',
    tagline: 'Twelve seats in a cellar, one menu, no menu.',
    description: 'Ava and Marco write this one together on the day. It starts at 21:30 and finishes when it finishes. Guests are invited by hand — if you can see this page, you are on the list.',
    hostId: 'u_ava', restaurantId: 'r_cellar', imageAsset: img.supperClub,
    gallery: [img.supperClub, img.wineCellar, img.omakase],
    start: at(12, 21, 30), durationMinutes: 240, seatsTotal: 12, seatsTaken: 12,
    pricePerSeat: 135, type: 'supperClub', audience: 'inviteOnly', menuStyle: 'tastingMenu',
    included: ['Eight courses', 'Wine pairing', 'Cellar seat', 'No end time'],
    tags: ['Invite only', 'Cellar', 'Wine pairing', 'Late'],
    dressCode: 'Smart casual',
    hostNote: 'This table is deliberately long and deliberately late. Do not book a morning after it.',
    attendeeIds: ['u_marco', 'u_yuki', 'u_sofia', 'u_leo', 'u_amara', 'u_tomas', 'u_ines', 'u_diego', 'u_priya', 'u_hugo', 'u_maple', 'u_jonas'],
    cancellation: 'Non-refundable — seats are transferred on request',
    menu: [
      { name: 'Course one', description: 'Decided on the day, based on what the market had.' },
      { name: 'Course two', description: 'Cooked in front of you at the pass.' },
      { name: 'Course three', description: 'Something from the cellar that Marco has been saving.', isSignature: true },
    ],
  },
  {
    id: 'e8', title: 'Sunday Long Lunch',
    tagline: 'A roast, too much wine, and no reason to leave before six.',
    description: 'Tomás has been running this lunch for three years. Everyone sits at two long tables in the shade, food arrives on platters, and there is no programme at all.',
    hostId: 'u_tomas', restaurantId: 'r_terrace', imageAsset: img.longTable,
    gallery: [img.longTable, img.gardenTerrace, img.trattoria],
    start: at(5, 13), durationMinutes: 300, seatsTotal: 18, seatsTaken: 12,
    pricePerSeat: 46, type: 'brunch', audience: 'public', menuStyle: 'familyStyle',
    included: ['One long table lunch', 'Two glasses of wine', 'Coffee', 'Garden seats'],
    tags: ['Daytime', 'Family style', 'New people', 'Vegetarian friendly'],
    hostNote: 'Children are very welcome at this one. Ask me about the vegetarian main when you book.',
    attendeeIds: ['u_ines', 'u_reem', 'u_kai', 'u_jonas'],
    cancellation: 'Free cancellation up to 24 hours before',
    menu: [
      { name: 'Slow-roast lamb', description: 'Seven hours, carved at the table.', isSignature: true },
      { name: 'Potatoes and bay', description: 'Roasted in the pan under the lamb.' },
      { name: 'Market salad', description: 'Whatever looked best that morning.' },
      { name: 'Rice pudding tart', description: 'Cinnamon, orange zest, no apologies.' },
    ],
  },
  {
    id: 'e9', title: 'Izakaya After Hours',
    tagline: 'Small plates, cold beer and the counter after the kitchen closes.',
    description: 'The service ends at eleven; the counter keeps going. Yuki hosts this one for people who want a soft landing after their own evening — arrive late, eat standing, stay as long as you like.',
    hostId: 'u_yuki', restaurantId: 'r_izakaya', imageAsset: img.izakaya,
    gallery: [img.izakaya, img.omakase, img.supperClub],
    start: at(8, 22), durationMinutes: 120, seatsTotal: 10, seatsTaken: 3,
    pricePerSeat: 58, type: 'dinner', audience: 'public', menuStyle: 'sharing',
    included: ['Six small plates', 'Two drinks', 'Counter seat'],
    tags: ['Late', 'Counter', 'Casual', 'Small plates'],
    dressCode: 'Whatever you are already wearing',
    hostNote: 'This is a standing counter, not a seated dinner. Perfect if you are coming alone.',
    attendeeIds: ['u_jonas', 'u_hugo'],
    cancellation: 'Free cancellation up to 12 hours before',
    menu: [
      { name: 'Karaage, yuzu mayo', description: 'Fried to order, eaten immediately.' },
      { name: 'Grilled rice balls', description: 'Miso glaze, crisp outside.', isSignature: true },
      { name: 'Pickles of the week', description: 'Whatever the kitchen has put down.' },
    ],
  },
  {
    id: 'e10', title: 'Farm Table Harvest Dinner',
    tagline: 'Twenty seats in the field the food came from.',
    description: 'Once a month Root & Ember moves the whole service outside. You eat at a trestle table under the vines, and everything on the table was picked within sight of it.',
    hostId: 'u_leo', restaurantId: 'r_farm', imageAsset: img.farmKitchen,
    gallery: [img.farmKitchen, img.fireFeast, img.longTable],
    start: at(10, 19), durationMinutes: 180, seatsTotal: 20, seatsTaken: 14,
    pricePerSeat: 68, type: 'dinner', audience: 'public', menuStyle: 'familyStyle',
    included: ['Five-course harvest menu', 'Farm tour before dinner', 'Wine or cider', 'Transport from the station'],
    tags: ['Outdoor', 'Farm', 'Vegetarian friendly', 'Day trip'],
    hostNote: 'There is a shuttle from the station at 18:15 and one back at 22:30. Book a seat when you reserve.',
    attendeeIds: ['u_tomas', 'u_amara', 'u_sofia', 'u_priya', 'u_reem', 'u_kai'],
    menu: [
      { name: 'Tomatoes and salt', description: 'Served as a course. They are that good.', isSignature: true },
      { name: 'Grilled courgette, mint', description: 'Straight from the field that morning.' },
      { name: 'Wood-fired chicken', description: 'Cooked in the outdoor oven.' },
      { name: 'Stone fruit and cream', description: 'Whatever is ripe.' },
    ],
  },
  {
    id: 'e11', title: 'Natural Wine 101',
    tagline: 'Six wines, no jargon, all your questions allowed.',
    description: 'Sofia built this for people who have stood in a wine shop feeling stupid. Six pours, a plate of things to eat with them, and a strict rule: nobody pretends to know anything.',
    hostId: 'u_sofia', restaurantId: 'r_cellar', imageAsset: img.wineTasting,
    gallery: [img.wineTasting, img.wineCellar, img.bistro],
    start: at(7, 18), durationMinutes: 120, seatsTotal: 12, seatsTaken: 5,
    pricePerSeat: 65, type: 'workshop', audience: 'public', menuStyle: 'tastingMenu',
    included: ['Six wine pours', 'Snack plate', 'Tasting sheet', 'Cellar seat'],
    tags: ['Wine', 'Beginner friendly', 'Indoor'],
    hostNote: 'No question is too basic here. I promise.',
    attendeeIds: ['u_hugo', 'u_maple', 'u_jonas', 'u_ines'],
    menu: [
      { name: 'Sparkling, pét-nat', description: 'How it is made, and why it tastes like that.' },
      { name: 'Skin contact white', description: 'The one that surprises everybody.', isSignature: true },
      { name: 'Light red, chilled', description: 'Served cold on purpose.' },
    ],
  },
  {
    id: 'e12', title: "Friends' Reunion Table",
    tagline: 'Nora’s table for the people who keep saying "we should do this more".',
    description: 'A small private table in the back room of Maison Lumen. Ten seats, one shared menu, and a rule that nobody talks about work before dessert.',
    hostId: 'u_me', restaurantId: 'r_bistro', imageAsset: img.trattoria,
    gallery: [img.trattoria, img.bistro, img.longTable],
    start: at(14, 20), durationMinutes: 180, seatsTotal: 10, seatsTaken: 4,
    pricePerSeat: 52, type: 'dinner', audience: 'friends', menuStyle: 'familyStyle',
    included: ['Private back room', 'Four shared courses', 'Welcome drink', 'Service'],
    tags: ['Private room', 'Friends', 'Sharing'],
    hostNote: 'Back room is ours from eight. Come up the side stairs and knock.',
    attendeeIds: ['u_ines', 'u_diego', 'u_maple'],
    cancellation: 'Free cancellation any time',
    menu: [
      { name: 'Bread, cultured butter', description: 'From the wood oven.' },
      { name: 'Hand-rolled cavatelli', description: 'With a slow tomato and basil sauce.', isSignature: true },
      { name: 'Roast chicken for the table', description: 'Two birds, carved and passed around.' },
      { name: 'Chocolate and olive oil', description: 'Warm, salted, shared.' },
    ],
  },
  // ── Already happened ──────────────────────────────────────────────────────
  {
    id: 'e13', title: 'Spring Truffle Table',
    tagline: 'Black truffle season, all four courses of it.',
    description: 'A seasonal table Nora hosted in spring, built entirely around a kilo of black truffle.',
    hostId: 'u_me', restaurantId: 'r_bistro', imageAsset: img.longTable,
    gallery: [img.longTable, img.trattoria],
    start: at(-12, 20), durationMinutes: 180, seatsTotal: 10, seatsTaken: 10,
    pricePerSeat: 52, type: 'dinner', audience: 'public', menuStyle: 'familyStyle',
    included: ['Four courses', 'Welcome drink'],
    tags: ['Seasonal', 'Sharing'],
    attendeeIds: ['u_diego', 'u_ines', 'u_priya', 'u_hugo', 'u_maple', 'u_jonas', 'u_reem', 'u_kai', 'u_tomas'],
    menu: [
      { name: 'Truffle menu', description: 'Four courses, generous shaving.' },
    ],
  },
  {
    id: 'e14', title: 'Cellar Tasting: Douro Edition',
    tagline: 'A vertical of Douro reds going back fifteen years.',
    description: 'Marco walked nine guests through a vertical tasting of Douro reds from the private racks.',
    hostId: 'u_marco', restaurantId: 'r_cellar', imageAsset: img.wineCellar,
    gallery: [img.wineCellar, img.wineTasting],
    start: at(-25, 19, 30), durationMinutes: 150, seatsTotal: 10, seatsTaken: 9,
    pricePerSeat: 120, type: 'tasting', audience: 'followers', menuStyle: 'tastingMenu',
    included: ['Six pours', 'Cheese board'],
    tags: ['Wine', 'Cellar'],
    attendeeIds: ['u_me', 'u_sofia', 'u_hugo', 'u_reem', 'u_ines', 'u_diego', 'u_kai', 'u_maple'],
    cancellation: 'Free cancellation up to 72 hours before',
    menu: [
      { name: 'Douro vertical', description: 'Six vintages, oldest first.' },
    ],
  },
  {
    id: 'e15', title: 'Sunday Long Lunch #4',
    tagline: 'The fourth in the series, and the one that filled fastest.',
    description: 'Nora hosted sixteen guests for a long Sunday lunch on the terrace.',
    hostId: 'u_me', restaurantId: 'r_terrace', imageAsset: img.gardenTerrace,
    gallery: [img.gardenTerrace, img.longTable],
    start: at(-5, 13), durationMinutes: 300, seatsTotal: 16, seatsTaken: 16,
    pricePerSeat: 46, type: 'brunch', audience: 'public', menuStyle: 'familyStyle',
    included: ['Long lunch', 'Two glasses of wine'],
    tags: ['Daytime', 'Family style'],
    attendeeIds: ['u_ines', 'u_reem', 'u_kai', 'u_tomas', 'u_priya'],
    cancellation: 'Free cancellation up to 24 hours before',
    menu: [
      { name: 'Terrace lunch', description: 'Four shared courses.' },
    ],
  },
  {
    id: 'e16', title: 'Sunset Table #6',
    tagline: 'The sixth sunset table of the season.',
    description: 'Yuki’s earlier sunset dinner on the same terrace.',
    hostId: 'u_yuki', restaurantId: 'r_terrace', imageAsset: img.rooftop,
    gallery: [img.rooftop, img.gardenTerrace],
    start: at(-9, 20), durationMinutes: 180, seatsTotal: 14, seatsTaken: 14,
    pricePerSeat: 62, type: 'dinner', audience: 'public', menuStyle: 'familyStyle',
    included: ['Welcome drink', 'Seven shared plates'],
    tags: ['Terrace', 'Sunset'],
    attendeeIds: ['u_me', 'u_ines', 'u_diego', 'u_priya', 'u_hugo', 'u_maple', 'u_reem', 'u_kai'],
    cancellation: 'Free cancellation up to 24 hours before',
    menu: [
      { name: 'Terrace menu', description: 'Seven shared plates.' },
    ],
  },
  // ── Nora's hosting history: powers the six-month earnings trend ──────────
  {
    id: 'e17', title: 'Truffle & Friends Table',
    tagline: 'Black truffle shaved over every course.',
    description: 'A spring table built around a kilo of black truffle at Maison Lumen.',
    hostId: 'u_me', restaurantId: 'r_bistro', imageAsset: img.trattoria,
    gallery: [img.trattoria, img.bistro],
    start: at(-165, 19), durationMinutes: 180, seatsTotal: 20, seatsTaken: 18,
    pricePerSeat: 52, type: 'dinner', audience: 'public', menuStyle: 'familyStyle',
    included: ['Four courses', 'Welcome drink'], tags: ['Seasonal', 'Sharing'],
    attendeeIds: ['u_ines', 'u_diego', 'u_priya', 'u_hugo', 'u_maple'],
    menu: [{ name: 'Truffle menu', description: 'Four courses, generous shaving.' }],
  },
  {
    id: 'e18', title: 'Neighbourhood Feast: Chiado',
    tagline: 'A long table for the whole street.',
    description: 'Twenty-four neighbours, one menu, nobody left the table before midnight.',
    hostId: 'u_me', restaurantId: 'r_bistro', imageAsset: img.longTable,
    gallery: [img.longTable, img.bistro],
    start: at(-135, 19), durationMinutes: 180, seatsTotal: 26, seatsTaken: 24,
    pricePerSeat: 52, type: 'dinner', audience: 'public', menuStyle: 'familyStyle',
    included: ['Four courses', 'Welcome drink'], tags: ['Family style'],
    attendeeIds: ['u_ines', 'u_diego', 'u_priya', 'u_hugo', 'u_jonas', 'u_reem'],
    menu: [{ name: 'Neighbourhood menu', description: 'Shared platters all night.' }],
  },
  {
    id: 'e19', title: 'Summer Terrace Table',
    tagline: 'Sunset dinner above the city.',
    description: 'Sixteen seats on the Terrazza Nove terrace at golden hour.',
    hostId: 'u_me', restaurantId: 'r_terrace', imageAsset: img.rooftop,
    gallery: [img.rooftop, img.gardenTerrace],
    start: at(-105, 19), durationMinutes: 180, seatsTotal: 18, seatsTaken: 16,
    pricePerSeat: 52, type: 'dinner', audience: 'public', menuStyle: 'familyStyle',
    included: ['Seven shared plates', 'Welcome spritz'], tags: ['Terrace', 'Sunset'],
    attendeeIds: ['u_priya', 'u_maple', 'u_reem', 'u_kai'],
    menu: [{ name: 'Terrace menu', description: 'Seven shared plates.' }],
  },
  {
    id: 'e20', title: 'Big Table: Bairro Night',
    tagline: 'Thirty-six seats, one long table.',
    description: 'The biggest table Nora has hosted — a full terrace buy-out for a summer night.',
    hostId: 'u_me', restaurantId: 'r_terrace', imageAsset: img.longTable,
    gallery: [img.longTable, img.rooftop],
    start: at(-75, 19), durationMinutes: 210, seatsTotal: 38, seatsTaken: 36,
    pricePerSeat: 46, type: 'dinner', audience: 'public', menuStyle: 'familyStyle',
    included: ['Long lunch menu', 'Two glasses of wine'], tags: ['Big table'],
    attendeeIds: ['u_ines', 'u_diego', 'u_priya', 'u_hugo', 'u_maple', 'u_jonas', 'u_reem', 'u_kai'],
    menu: [{ name: 'Bairro menu', description: 'Platters for a full terrace.' }],
  },
  {
    id: 'e21', title: 'Harvest Table at the Farm',
    tagline: 'Dinner in the field the food came from.',
    description: 'A harvest dinner at Root & Ember, everything picked that morning.',
    hostId: 'u_me', restaurantId: 'r_farm', imageAsset: img.farmKitchen,
    gallery: [img.farmKitchen, img.fireFeast],
    start: at(-45, 19), durationMinutes: 180, seatsTotal: 24, seatsTaken: 22,
    pricePerSeat: 52, type: 'dinner', audience: 'public', menuStyle: 'familyStyle',
    included: ['Five-course harvest menu', 'Farm tour'], tags: ['Farm', 'Outdoor'],
    attendeeIds: ['u_tomas', 'u_amara', 'u_priya', 'u_reem'],
    menu: [{ name: 'Harvest menu', description: 'Field to table.' }],
  },
  {
    id: 'e22', title: 'Autumn Supper Club',
    tagline: 'Twenty-eight seats in the cellar.',
    description: 'A candle-lit supper club in The Vault before the season turned.',
    hostId: 'u_me', restaurantId: 'r_cellar', imageAsset: img.supperClub,
    gallery: [img.supperClub, img.wineCellar],
    start: at(-15, 19), durationMinutes: 210, seatsTotal: 30, seatsTaken: 28,
    pricePerSeat: 52, type: 'supperClub', audience: 'public', menuStyle: 'tastingMenu',
    included: ['Six courses', 'Wine pairing'], tags: ['Cellar', 'Supper club'],
    attendeeIds: ['u_ines', 'u_diego', 'u_hugo', 'u_maple', 'u_jonas'],
    menu: [{ name: 'Autumn menu', description: 'Six courses, one cellar.' }],
  },
];

// ── Bookings made by the current user ────────────────────────────────────────

const bookings = [
  { id: 'b1', eventId: 'e1', guestId: 'u_me', seats: 2, pricePerSeat: 95, createdAt: at(-3, 21, 12), reference: 'DC-8H4K2', paymentLabel: 'Visa •••• 4242', status: 'confirmed', checkedIn: false },
  { id: 'b2', eventId: 'e4', guestId: 'u_me', seats: 1, pricePerSeat: 120, createdAt: at(-1, 9, 40), reference: 'DC-3M9QW', paymentLabel: 'Visa •••• 4242', status: 'confirmed', checkedIn: false },
  { id: 'b3', eventId: 'e8', guestId: 'u_me', seats: 3, pricePerSeat: 46, createdAt: at(-2, 18, 5), reference: 'DC-6T1ZP', paymentLabel: 'Apple Pay', status: 'confirmed', checkedIn: false },
  { id: 'b4', eventId: 'e16', guestId: 'u_me', seats: 2, pricePerSeat: 62, createdAt: at(-16, 12, 30), reference: 'DC-2J7YR', paymentLabel: 'Visa •••• 4242', status: 'completed', checkedIn: true },
  { id: 'b5', eventId: 'e14', guestId: 'u_me', seats: 1, pricePerSeat: 120, createdAt: at(-31, 20, 14), reference: 'DC-5B8ND', paymentLabel: 'Google Pay', status: 'completed', checkedIn: true },
];

// ── Host earnings ────────────────────────────────────────────────────────────

const payouts = [
  { id: 'p1', eventId: 'e13', eventTitle: 'Spring Truffle Table', date: at(-12, 20), seatsSold: 10, gross: 520, commission: 52, status: 'paid' },
  { id: 'p2', eventId: 'e15', eventTitle: 'Sunday Long Lunch #4', date: at(-5, 13), seatsSold: 16, gross: 736, commission: 73.6, status: 'inTransit' },
  { id: 'p3', eventId: 'e12', eventTitle: "Friends' Reunion Table", date: at(14, 20), seatsSold: 4, gross: 208, commission: 20.8, status: 'scheduled' },
  // Historical lines — the earnings trend derives from these.
  { id: 'p4', eventId: 'e17', eventTitle: 'Truffle & Friends Table', date: at(-165, 19), seatsSold: 18, gross: 936, commission: 93.6, status: 'paid' },
  { id: 'p5', eventId: 'e18', eventTitle: 'Neighbourhood Feast: Chiado', date: at(-135, 19), seatsSold: 24, gross: 1248, commission: 124.8, status: 'paid' },
  { id: 'p6', eventId: 'e19', eventTitle: 'Summer Terrace Table', date: at(-105, 19), seatsSold: 16, gross: 832, commission: 83.2, status: 'paid' },
  { id: 'p7', eventId: 'e20', eventTitle: 'Big Table: Bairro Night', date: at(-75, 19), seatsSold: 36, gross: 1656, commission: 165.6, status: 'paid' },
  { id: 'p8', eventId: 'e21', eventTitle: 'Harvest Table at the Farm', date: at(-45, 19), seatsSold: 22, gross: 1144, commission: 114.4, status: 'paid' },
  { id: 'p9', eventId: 'e22', eventTitle: 'Autumn Supper Club', date: at(-15, 19), seatsSold: 28, gross: 1456, commission: 145.6, status: 'paid' },
];

// ── Saved tables (the app's heart button) ──────────────────────────────

const savedEvents: Array<[userId: string, eventId: string]> = [
  ['u_me', 'e2'],
  ['u_me', 'e7'],
];

// ── Activity feed for the signed-in user ──────────────────────────────

interface ActivitySeed {
  id: string; kind: string; title: string; body: string;
  createdAt: Date; actorId?: string; eventId?: string;
  amount?: number; isUnread?: boolean;
}

const activity: ActivitySeed[] = [
  { id: 'n1', kind: 'newGuest', title: '2 new guests joined your table', body: "Friends' Reunion Table just sold four more seats.", createdAt: at(0, 8, 12), eventId: 'e12', isUnread: true },
  { id: 'n2', kind: 'payout', title: 'Payout on the way', body: '€662.40 from Sunday Long Lunch #4 is in transit.', createdAt: at(0, 7, 30), amount: 662.4, isUnread: true },
  { id: 'n3', kind: 'reminder', title: 'Your table is tomorrow', body: "Chef's Counter Omakase starts tomorrow at 7:30 pm.", createdAt: at(-1, 18), eventId: 'e1', isUnread: true },
  { id: 'n4', kind: 'follower', title: 'Ava Moretti started following you', body: 'You now have 1,284 followers.', createdAt: at(-1, 11, 20), actorId: 'u_ava' },
  { id: 'n5', kind: 'review', title: 'New review for Spring Truffle Table', body: '“Nora runs a table like a natural host.” — Diego Costa', createdAt: at(-11, 10, 5), actorId: 'u_diego', eventId: 'e13' },
  { id: 'n6', kind: 'invite', title: 'Invitation: Midnight Supper Club', body: 'Ava Moretti invited you to an invite-only table in the cellar.', createdAt: at(-4, 16, 45), actorId: 'u_ava', eventId: 'e7' },
  { id: 'n7', kind: 'payment', title: 'Payment confirmed', body: '€127.20 for Rare Vintages in the Cellar.', createdAt: at(-1, 9, 41), amount: 127.2, eventId: 'e4' },
];

// ── Table chat threads (for Nora's booked/hosted events) ──────────────

interface ChatSeed {
  id: string; eventId: string; authorId: string | null; text: string;
  sentAt: Date; isSystem?: boolean;
}

const chatMessages: ChatSeed[] = [
  // Chef's Counter Omakase (Nora booked two seats)
  { id: 'c1', eventId: 'e1', authorId: null, text: 'You joined this table. Say hello to the group!', sentAt: at(-3, 21, 15), isSystem: true },
  { id: 'c2', eventId: 'e1', authorId: 'u_ava', text: 'Welcome everyone. I am shopping for the counter on Saturday morning — tell me now if there is anything you do not eat.', sentAt: at(-2, 9, 4) },
  { id: 'c3', eventId: 'e1', authorId: 'u_ines', text: 'No shellfish for me please 🙏', sentAt: at(-2, 9, 30) },
  { id: 'c4', eventId: 'e1', authorId: 'u_me', text: 'Coming with one friend — she does not drink alcohol. Is there a non-alcoholic pairing?', sentAt: at(-2, 12, 41) },
  { id: 'c5', eventId: 'e1', authorId: 'u_ava', text: 'Yes — house-made kombucha and a roasted barley tea, both poured alongside the sake courses. No problem at all.', sentAt: at(-2, 13, 2) },
  { id: 'c6', eventId: 'e1', authorId: 'u_marco', text: 'I will be at the counter too. Bringing something fun for after the last course.', sentAt: at(-1, 19, 48) },
  // Rare Vintages in the Cellar
  { id: 'c7', eventId: 'e4', authorId: null, text: 'You joined this table. Say hello to the group!', sentAt: at(-1, 9, 45), isSystem: true },
  { id: 'c8', eventId: 'e4', authorId: 'u_marco', text: 'The cellar is booked for us. I have pulled six bottles — one of them you will not find on any list.', sentAt: at(-1, 11) },
  { id: 'c9', eventId: 'e4', authorId: 'u_me', text: 'Looking forward to it. Any cheese with the Jura?', sentAt: at(-1, 12, 20) },
  { id: 'c10', eventId: 'e4', authorId: 'u_marco', text: 'A 24-month Comté, plus toasted almonds with the port.', sentAt: at(-1, 13) },
  // Sunday Long Lunch
  { id: 'c11', eventId: 'e8', authorId: null, text: 'You joined this table. Say hello to the group!', sentAt: at(-2, 18, 10), isSystem: true },
  { id: 'c12', eventId: 'e8', authorId: 'u_tomas', text: 'Long table in the shade is ours from one. Lamb goes in the oven at seven in the morning — come hungry.', sentAt: at(-2, 9) },
  { id: 'c13', eventId: 'e8', authorId: 'u_me', text: 'We are three — one vegetarian.', sentAt: at(-1, 20) },
  { id: 'c14', eventId: 'e8', authorId: 'u_tomas', text: 'Noted, a market-vegetable platter comes out with the lamb.', sentAt: at(-1, 21) },
  // Friends' Reunion Table (Nora hosts)
  { id: 'c15', eventId: 'e12', authorId: null, text: 'Table chat is open for Friends\' Reunion Table.', sentAt: at(-6, 22), isSystem: true },
  { id: 'c16', eventId: 'e12', authorId: 'u_me', text: 'Room is ours from eight. Side stairs, knock twice if the door is shut.', sentAt: at(-6, 22, 5) },
  { id: 'c17', eventId: 'e12', authorId: 'u_ines', text: 'Is it too early to ask about the chocolate course?', sentAt: at(-5, 10) },
  { id: 'c18', eventId: 'e12', authorId: 'u_me', text: 'It is never too early. Warm, salted, shared.', sentAt: at(-5, 10, 30) },
  // Cellar Tasting: Douro Edition (past)
  { id: 'c19', eventId: 'e14', authorId: null, text: 'You joined this table. Say hello to the group!', sentAt: at(-31, 20, 20), isSystem: true },
  { id: 'c20', eventId: 'e14', authorId: 'u_marco', text: 'Six vintages, oldest first. Take your time with the 1994.', sentAt: at(-31, 19) },
  { id: 'c21', eventId: 'e14', authorId: 'u_me', text: 'That one stopped the table for a full minute.', sentAt: at(-30, 12) },
  // Sunset Table #6 (past)
  { id: 'c22', eventId: 'e16', authorId: null, text: 'You joined this table. Say hello to the group!', sentAt: at(-16, 12, 35), isSystem: true },
  { id: 'c23', eventId: 'e16', authorId: 'u_yuki', text: 'Sunset is at 8:41 — be on the terrace by 8:15 so we can pour before the light goes.', sentAt: at(-16, 13) },
  { id: 'c24', eventId: 'e16', authorId: 'u_me', text: 'On our way up the hill now.', sentAt: at(-9, 19, 50) },
];

// ── Reviews ──────────────────────────────────────────────────────────────────

const reviews = [
  { id: 'rv1', authorId: 'u_ines', eventId: 'e1', eventTitle: "Chef's Counter Omakase", rating: 5, text: 'I came alone and left with four phone numbers. Ava explained every piece without ever making it feel like a lecture.', createdAt: at(-20, 22) },
  { id: 'rv2', authorId: 'u_diego', eventId: 'e13', eventTitle: 'Spring Truffle Table', rating: 5, text: 'Nora runs a table like a natural host. The truffle course alone was worth the seat price.', createdAt: at(-11, 10) },
  { id: 'rv3', authorId: 'u_priya', eventId: 'e16', eventTitle: 'Sunset Table #6', rating: 4.8, text: 'The terrace is even better than the photos. Slightly rushed at the start, but the table found its rhythm by the second course.', createdAt: at(-8, 9) },
  { id: 'rv4', authorId: 'u_hugo', eventId: 'e14', eventTitle: 'Cellar Tasting: Douro Edition', rating: 5, text: 'Marco knows exactly how much detail to give. Six pours and I finally understood what people mean by structure.', createdAt: at(-24, 11) },
];

// ── Writer ───────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `TRUNCATE reviews, bookings, payouts, menu_items, chat_messages, activity,
                saved_events, auth_tokens, otp_codes, dinner_events, follows,
                restaurants, users RESTART IDENTITY CASCADE`,
    );

    for (const u of users) {
      await client.query(
        `INSERT INTO users (id, name, handle, phone, city, bio, followers, following,
                            dinners_hosted, dinners_joined, rating, review_count,
                            avatar_asset, badges, tastes, accent_hex, joined_year)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)`,
        [u.id, u.name, u.handle, u.phone ?? null, u.city, u.bio, u.followers,
         u.following, u.dinnersHosted, u.dinnersJoined, u.rating, u.reviewCount,
         u.avatarAsset, u.badges, u.tastes, u.accentHex ?? null, u.joinedYear],
      );
    }

    for (const [follower, followee] of follows) {
      await client.query(
        'INSERT INTO follows (follower_id, followee_id) VALUES ($1, $2)',
        [follower, followee],
      );
    }

    for (const r of restaurants) {
      await client.query(
        `INSERT INTO restaurants (id, name, cuisine, neighborhood, address, rating,
                                  review_count, price_level, distance_meters, hero_asset,
                                  gallery, description, tags, is_partner, partner_perk,
                                  opening_hours, seats_available)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)`,
        [r.id, r.name, r.cuisine, r.neighborhood, r.address, r.rating,
         r.reviewCount, r.priceLevel, r.distanceMeters, r.heroAsset,
         r.gallery, r.description, r.tags, r.isPartner, r.partnerPerk,
         r.openingHours, r.seatsAvailable],
      );
    }

    for (const e of events) {
      await client.query(
        `INSERT INTO dinner_events (id, title, tagline, description, host_id,
                                    restaurant_id, image_asset, gallery, start_at,
                                    duration_minutes, seats_total, seats_taken,
                                    price_per_seat, type, audience, menu_style,
                                    included, tags, is_featured, host_note, language,
                                    dress_code, cancellation, attendee_ids)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24)`,
        [e.id, e.title, e.tagline, e.description, e.hostId, e.restaurantId,
         e.imageAsset, e.gallery, e.start, e.durationMinutes, e.seatsTotal,
         e.seatsTaken, e.pricePerSeat, e.type, e.audience, e.menuStyle,
         e.included, e.tags, e.isFeatured ?? false, e.hostNote ?? '',
         e.language ?? 'English', e.dressCode ?? 'Smart casual',
         e.cancellation ?? 'Free cancellation up to 48 hours before', e.attendeeIds],
      );

      for (const [i, item] of e.menu.entries()) {
        await client.query(
          `INSERT INTO menu_items (event_id, position, name, description, pairing, is_signature)
           VALUES ($1,$2,$3,$4,$5,$6)`,
          [e.id, i, item.name, item.description, item.pairing ?? null,
           item.isSignature ?? false],
        );
      }
    }

    for (const b of bookings) {
      await client.query(
        `INSERT INTO bookings (id, event_id, guest_id, seats, price_per_seat,
                               created_at, reference, payment_label, status, checked_in)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
        [b.id, b.eventId, b.guestId, b.seats, b.pricePerSeat, b.createdAt,
         b.reference, b.paymentLabel, b.status, b.checkedIn],
      );
    }

    for (const p of payouts) {
      await client.query(
        `INSERT INTO payouts (id, event_id, event_title, date, seats_sold, gross, commission, status)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
        [p.id, p.eventId, p.eventTitle, p.date, p.seatsSold, p.gross, p.commission, p.status],
      );
    }

    for (const r of reviews) {
      await client.query(
        `INSERT INTO reviews (id, author_id, event_id, event_title, rating, text, created_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [r.id, r.authorId, r.eventId, r.eventTitle, r.rating, r.text, r.createdAt],
      );
    }

    for (const [userId, eventId] of savedEvents) {
      await client.query(
        'INSERT INTO saved_events (user_id, event_id) VALUES ($1, $2)',
        [userId, eventId],
      );
    }

    for (const n of activity) {
      await client.query(
        `INSERT INTO activity (id, user_id, kind, title, body, actor_id, event_id,
                               amount, is_unread, created_at)
         VALUES ($1,'u_me',$2,$3,$4,$5,$6,$7,$8,$9)`,
        [n.id, n.kind, n.title, n.body, n.actorId ?? null, n.eventId ?? null,
         n.amount ?? null, n.isUnread ?? false, n.createdAt],
      );
    }

    for (const c of chatMessages) {
      await client.query(
        `INSERT INTO chat_messages (id, event_id, author_id, text, sent_at, is_system)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [c.id, c.eventId, c.authorId, c.text, c.sentAt, c.isSystem ?? false],
      );
    }

    await client.query('COMMIT');

    const counts = await client.query(
      `SELECT (SELECT count(*) FROM users) users,
              (SELECT count(*) FROM restaurants) restaurants,
              (SELECT count(*) FROM dinner_events) events,
              (SELECT count(*) FROM menu_items) menu_items,
              (SELECT count(*) FROM bookings) bookings,
              (SELECT count(*) FROM payouts) payouts,
              (SELECT count(*) FROM reviews) reviews,
              (SELECT count(*) FROM follows) follows,
              (SELECT count(*) FROM chat_messages) chat_messages,
              (SELECT count(*) FROM activity) activity,
              (SELECT count(*) FROM saved_events) saved_events`,
    );
    console.log('Seeded dinecircle:', counts.rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((error) => {
  console.error('Seed failed:', error);
  process.exit(1);
});
