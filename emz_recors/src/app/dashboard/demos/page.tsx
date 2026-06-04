"use client";

import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Music, Search, Download, X, Check } from "lucide-react";
import { useState } from "react";

const initialDemos = [
  {
    id: "1",
    artistName: "DJ Manu",
    email: "manu@email.com",
    link: "https://soundcloud.com/...",
    genre: "Afro Beat",
    status: "pending" as const,
    description:
      "Projet de 3 titres afro-beat avec influences coupé-décalé. Stems disponibles.",
    createdAt: "2026-06-02T09:00:00",
  },
  {
    id: "2",
    artistName: "Lyna B",
    email: "lyna@email.com",
    link: "https://dropbox.com/...",
    genre: "RnB",
    status: "reviewing" as const,
    description:
      "EP de 5 titres RnB contemporain. Influences Tems, Ayra Starr.",
    createdAt: "2026-05-28T15:30:00",
  },
  {
    id: "3",
    artistName: "Le Flow",
    email: "leflow@email.com",
    link: "https://soundcloud.com/...",
    genre: "Rap",
    status: "accepted" as const,
    description: "Single rap engagé, texte fort, prod solide.",
    createdAt: "2026-05-20T11:00:00",
  },
  {
    id: "4",
    artistName: "K-Stone",
    email: "kstone@email.com",
    link: "https://drive.google.com/...",
    genre: "Afro Pop",
    status: "rejected" as const,
    description: "Son pas assez abouti, mix à retravailler.",
    createdAt: "2026-05-15T08:00:00",
  },
];

const statusBadge = {
  pending: { label: "En attente", class: "bg-amber-500/10 text-amber-400 border-amber-500/20" },
  reviewing: { label: "En écoute", class: "bg-blue-500/10 text-blue-400 border-blue-500/20" },
  accepted: { label: "Acceptée", class: "bg-green-500/10 text-green-400 border-green-500/20" },
  rejected: { label: "Refusée", class: "bg-red-500/10 text-red-400 border-red-500/20" },
};

export default function DemosPage() {
  const [demos, setDemos] = useState(initialDemos);
  const [search, setSearch] = useState("");

  const filtered = demos.filter(
    (d) =>
      d.artistName.toLowerCase().includes(search.toLowerCase()) ||
      d.genre.toLowerCase().includes(search.toLowerCase())
  );

  const updateStatus = (id: string, status: "pending" | "reviewing" | "accepted" | "rejected") => {
    setDemos((prev) => prev.map((d) => (d.id === id ? { ...d, status } : d)));
  };

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold tracking-tight">Démos reçues</h1>
        <p className="text-muted-foreground">
          Gérez les maquettes soumises par les artistes.
        </p>
      </div>

      <div className="relative mb-6 max-w-md">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          placeholder="Rechercher par artiste ou genre..."
          className="pl-9"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      <div className="space-y-4">
        {filtered.map((demo) => {
          const badge = statusBadge[demo.status];
          return (
            <Card
              key={demo.id}
              className="border-border/40 bg-card/50 backdrop-blur p-5"
            >
              <div className="flex items-start justify-between">
                <div className="flex items-start gap-4">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-primary/10">
                    <Music className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <div className="flex items-center gap-3">
                      <h3 className="font-semibold">{demo.artistName}</h3>
                      <Badge
                        variant="outline"
                        className={`text-xs ${badge.class}`}
                      >
                        {badge.label}
                      </Badge>
                      <Badge variant="secondary" className="text-xs">
                        {demo.genre}
                      </Badge>
                    </div>
                    <p className="mt-1 text-sm text-muted-foreground">
                      {demo.description}
                    </p>
                    <div className="mt-2 flex items-center gap-4 text-xs text-muted-foreground">
                      <span>{demo.email}</span>
                      <a
                        href={demo.link}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-primary hover:underline"
                      >
                        Écouter →
                      </a>
                      <span>
                        Reçue le{" "}
                        {new Date(demo.createdAt).toLocaleDateString("fr-FR")}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  {demo.status === "pending" && (
                    <>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => updateStatus(demo.id, "reviewing")}
                      >
                        Marquer en écoute
                      </Button>
                    </>
                  )}
                  {demo.status === "reviewing" && (
                    <>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="text-green-400"
                        onClick={() => updateStatus(demo.id, "accepted")}
                      >
                        <Check className="mr-1 h-3 w-3" />
                        Accepter
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="text-red-400"
                        onClick={() => updateStatus(demo.id, "rejected")}
                      >
                        <X className="mr-1 h-3 w-3" />
                        Refuser
                      </Button>
                    </>
                  )}
                  {demo.status === "accepted" && (
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-muted-foreground"
                    >
                      <Download className="mr-1 h-3 w-3" />
                      Télécharger
                    </Button>
                  )}
                </div>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
