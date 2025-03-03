CREATE TABLE listings (
    "time" TIMESTAMPTZ NOT NULL,
    "ip" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "map" TEXT NOT NULL,
    "players" INTEGER NOT NULL,
    "pw_required" BOOLEAN NOT NULL,
    "version" TEXT NOT NULL,
    "hardcore" BOOLEAN NOT NULL,
    "ping" INTEGER NOT NULL
);

CREATE INDEX listings_time_idx ON public.listings ("time");

CREATE INDEX listings_time_players_idx ON listings (time)
WHERE players > 0;

CREATE INDEX listings_name_idx ON public.listings (name, "time");
