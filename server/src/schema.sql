-- DineCircle MVP schema. Single source of truth; re-runnable.
-- Money is numeric(10,2); enum-like columns are text + CHECK (the API returns
-- the same identifiers the Flutter app uses).

CREATE TABLE IF NOT EXISTS users (
  id             text PRIMARY KEY,
  name           text NOT NULL,
  handle         text NOT NULL UNIQUE,
  phone          text,
  city           text NOT NULL,
  bio            text NOT NULL DEFAULT '',
  followers      integer NOT NULL DEFAULT 0,
  following      integer NOT NULL DEFAULT 0,
  dinners_hosted integer NOT NULL DEFAULT 0,
  dinners_joined integer NOT NULL DEFAULT 0,
  rating         numeric(3,2) NOT NULL DEFAULT 0,
  review_count   integer NOT NULL DEFAULT 0,
  avatar_asset   text,
  badges         text[] NOT NULL DEFAULT '{}',
  tastes         text[] NOT NULL DEFAULT '{}',
  accent_hex     text,
  joined_year    integer NOT NULL DEFAULT 2024,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS restaurants (
  id              text PRIMARY KEY,
  name            text NOT NULL,
  cuisine         text NOT NULL,
  neighborhood    text NOT NULL,
  address         text NOT NULL,
  rating          numeric(3,2) NOT NULL DEFAULT 0,
  review_count    integer NOT NULL DEFAULT 0,
  price_level     integer NOT NULL DEFAULT 2 CHECK (price_level BETWEEN 1 AND 4),
  distance_meters integer NOT NULL DEFAULT 0,
  hero_asset      text NOT NULL,
  gallery         text[] NOT NULL DEFAULT '{}',
  description     text NOT NULL DEFAULT '',
  tags            text[] NOT NULL DEFAULT '{}',
  is_partner      boolean NOT NULL DEFAULT false,
  partner_perk    text,
  opening_hours   text NOT NULL DEFAULT '',
  seats_available integer NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dinner_events (
  id               text PRIMARY KEY,
  title            text NOT NULL,
  tagline          text NOT NULL DEFAULT '',
  description      text NOT NULL DEFAULT '',
  host_id          text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  restaurant_id    text NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  image_asset      text NOT NULL,
  gallery          text[] NOT NULL DEFAULT '{}',
  start_at         timestamptz NOT NULL,
  duration_minutes integer NOT NULL DEFAULT 150,
  seats_total      integer NOT NULL CHECK (seats_total >= 0),
  seats_taken      integer NOT NULL DEFAULT 0 CHECK (seats_taken >= 0 AND seats_taken <= seats_total),
  price_per_seat   numeric(10,2) NOT NULL CHECK (price_per_seat >= 0),
  type             text NOT NULL DEFAULT 'dinner'
                   CHECK (type IN ('dinner','tasting','supperClub','brunch','workshop','festival')),
  audience         text NOT NULL DEFAULT 'public'
                   CHECK (audience IN ('public','followers','friends','inviteOnly')),
  menu_style       text NOT NULL DEFAULT 'familyStyle'
                   CHECK (menu_style IN ('setMenu','tastingMenu','familyStyle','sharing','buffet')),
  included         text[] NOT NULL DEFAULT '{}',
  tags             text[] NOT NULL DEFAULT '{}',
  is_featured      boolean NOT NULL DEFAULT false,
  host_note        text NOT NULL DEFAULT '',
  language         text NOT NULL DEFAULT 'English',
  dress_code       text NOT NULL DEFAULT 'Smart casual',
  cancellation     text NOT NULL DEFAULT 'Free cancellation up to 48 hours before',
  attendee_ids     text[] NOT NULL DEFAULT '{}',
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS menu_items (
  id           serial PRIMARY KEY,
  event_id     text NOT NULL REFERENCES dinner_events(id) ON DELETE CASCADE,
  position     integer NOT NULL DEFAULT 0,
  name         text NOT NULL,
  description  text NOT NULL DEFAULT '',
  pairing      text,
  is_signature boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS bookings (
  id             text PRIMARY KEY,
  event_id       text NOT NULL REFERENCES dinner_events(id) ON DELETE CASCADE,
  guest_id       text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  seats          integer NOT NULL CHECK (seats > 0),
  price_per_seat numeric(10,2) NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  reference      text NOT NULL UNIQUE,
  payment_label  text NOT NULL DEFAULT '',
  status         text NOT NULL DEFAULT 'confirmed'
                 CHECK (status IN ('confirmed','pending','completed','cancelled')),
  checked_in     boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS payouts (
  id          text PRIMARY KEY,
  event_id    text NOT NULL,
  event_title text NOT NULL,
  date        timestamptz NOT NULL,
  seats_sold  integer NOT NULL DEFAULT 0,
  gross       numeric(10,2) NOT NULL DEFAULT 0,
  commission  numeric(10,2) NOT NULL DEFAULT 0,
  status      text NOT NULL DEFAULT 'scheduled'
              CHECK (status IN ('paid','inTransit','scheduled'))
);

CREATE TABLE IF NOT EXISTS reviews (
  id          text PRIMARY KEY,
  author_id   text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id    text NOT NULL,
  event_title text NOT NULL,
  rating      numeric(3,2) NOT NULL CHECK (rating BETWEEN 0 AND 5),
  text        text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS follows (
  follower_id text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  followee_id text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, followee_id),
  CHECK (follower_id <> followee_id)
);

-- Phone sign-in (mock SMS for the MVP: the code is always 123456).
CREATE TABLE IF NOT EXISTS otp_codes (
  phone      text PRIMARY KEY,
  code       text NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auth_tokens (
  token      text PRIMARY KEY,
  user_id    text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id        text PRIMARY KEY,
  event_id  text NOT NULL REFERENCES dinner_events(id) ON DELETE CASCADE,
  author_id text REFERENCES users(id) ON DELETE SET NULL,
  text      text NOT NULL,
  sent_at   timestamptz NOT NULL DEFAULT now(),
  is_system boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS activity (
  id         text PRIMARY KEY,
  user_id    text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind       text NOT NULL
             CHECK (kind IN ('newGuest','payment','reminder','follower','payout','invite','review')),
  title      text NOT NULL,
  body       text NOT NULL,
  actor_id   text REFERENCES users(id) ON DELETE SET NULL,
  event_id   text REFERENCES dinner_events(id) ON DELETE CASCADE,
  amount     numeric(10,2),
  is_unread  boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS saved_events (
  user_id   text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id  text NOT NULL REFERENCES dinner_events(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, event_id)
);

-- Existing installs predate the phone column; keep the schema re-runnable.
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone text;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone ON users(phone) WHERE phone IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_events_start_at      ON dinner_events(start_at);
CREATE INDEX IF NOT EXISTS idx_events_host          ON dinner_events(host_id);
CREATE INDEX IF NOT EXISTS idx_events_restaurant    ON dinner_events(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_events_type          ON dinner_events(type);
CREATE INDEX IF NOT EXISTS idx_menu_items_event     ON menu_items(event_id);
CREATE INDEX IF NOT EXISTS idx_bookings_guest       ON bookings(guest_id);
CREATE INDEX IF NOT EXISTS idx_bookings_event       ON bookings(event_id);
CREATE INDEX IF NOT EXISTS idx_reviews_event        ON reviews(event_id);
CREATE INDEX IF NOT EXISTS idx_reviews_author       ON reviews(author_id);
CREATE INDEX IF NOT EXISTS idx_chat_event           ON chat_messages(event_id, sent_at);
CREATE INDEX IF NOT EXISTS idx_activity_user        ON activity(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_auth_tokens_user     ON auth_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_events_user    ON saved_events(user_id);
