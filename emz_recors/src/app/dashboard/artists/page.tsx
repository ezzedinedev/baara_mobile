"use client";

import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Music, Plus, ExternalLink } from "lucide-react";

const artists = [
  {
    name: "Kayna",
    genre: "Afro Beat / Urban",
    status: "Actif",
    streams: "1.2M",
    since: "Jan 2025",
  },
  {
    name: "Kemèl",
    genre: "Afro Pop / RnB",
    status: "Actif",
    streams: "450K",
    since: "Mai 2026",
  },
  {
    name: "Marez on the track",
    genre: "Producteur",
    status: "Actif",
    streams: "-",
    since: "2024",
  },
];

export default function ArtistsPage() {
  return (
    <div className="p-8">
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Artistes</h1>
          <p className="text-muted-foreground">
            Gérez le roster du label.
          </p>
        </div>
        <Button>
          <Plus className="mr-2 h-4 w-4" />
          Ajouter un artiste
        </Button>
      </div>

      <div className="space-y-4">
        {artists.map((artist) => (
          <Card
            key={artist.name}
            className="border-border/40 bg-card/50 backdrop-blur p-5"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="flex h-14 w-14 items-center justify-center rounded-full bg-gradient-to-br from-primary/20 to-muted">
                  <Music className="h-6 w-6 text-primary" />
                </div>
                <div>
                  <h3 className="font-semibold">{artist.name}</h3>
                  <div className="mt-1 flex items-center gap-3">
                    <Badge variant="secondary" className="text-xs">
                      {artist.genre}
                    </Badge>
                    <Badge
                      variant="outline"
                      className="text-xs border-green-500/20 text-green-400 bg-green-500/10"
                    >
                      {artist.status}
                    </Badge>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-8">
                <div className="text-right">
                  <p className="text-sm font-medium">{artist.streams}</p>
                  <p className="text-xs text-muted-foreground">Streams</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium">{artist.since}</p>
                  <p className="text-xs text-muted-foreground">Depuis</p>
                </div>
                <Button variant="ghost" size="sm">
                  <ExternalLink className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
