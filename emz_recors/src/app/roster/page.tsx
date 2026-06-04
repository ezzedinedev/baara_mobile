"use client";

import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Globe, Music, Headphones, Sparkles, Disc3 } from "lucide-react";
import { motion } from "framer-motion";
import { AnimatedSection, StaggerGrid, StaggerItem } from "@/components/ui/animations/animated-section";
import { AnimatedGradient } from "@/components/ui/animations/animated-gradient";

const artists = [
  {
    name: "Kayna",
    slug: "kayna",
    genre: "Afro Beat / Urban",
    bio: "Artiste polyvalent à la voix chaude et aux mélodies entraînantes. Kayna impose son style afro-urbain avec des textes qui parlent à toute une génération.",
    stats: "1.2M streams",
    color: "from-amber-500/20 to-orange-500/10",
    image: null,
    spotify: "#",
    appleMusic: "#",
    boomplay: "#",
    audiomack: "#",
  },
  {
    name: "Kemèl",
    slug: "kemel",
    genre: "Afro Pop / RnB",
    bio: "Nouvelle signature du label, Kemèl apporte une fraîcheur et une sensibilité rare. Ses sonorités afro-pop teintées de RnB séduisent un public large.",
    stats: "Nouvelle signature",
    color: "from-purple-500/20 to-pink-500/10",
    image: null,
    spotify: "#",
    appleMusic: "#",
    boomplay: "#",
  },
  {
    name: "Marez on the track",
    slug: "marez-on-the-track",
    genre: "Beatmaker / Producteur",
    bio: "Ingénieur du son et beatmaker attitré du label. Marez on the track est le chef d'orchestre de la signature sonore EMZ RECORD.",
    stats: "50+ productions",
    color: "from-blue-500/20 to-cyan-500/10",
    image: null,
    spotify: "#",
    appleMusic: "#",
  },
];

export default function RosterPage() {
  return (
    <div className="relative pt-24">
      <AnimatedGradient />

      <div className="relative mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="mb-16 text-center"
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.2 }}
          >
            <Badge variant="outline" className="mb-4 border-primary/30 text-primary">
              <Sparkles className="mr-1.5 h-3.5 w-3.5" />
              Notre force artistique
            </Badge>
          </motion.div>
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
            Le <span className="text-gradient">Roster</span>
          </h1>
          <p className="mx-auto mt-4 max-w-2xl text-lg text-muted-foreground">
            Découvrez les artistes qui font la signature sonore d&apos;EMZ RECORD.
          </p>
        </motion.div>

        <StaggerGrid className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          {artists.map((artist) => (
            <StaggerItem key={artist.slug}>
              <Card className="group h-full border-border/40 bg-card/50 backdrop-blur transition-all duration-500 hover:border-primary/30 hover:shadow-xl hover:shadow-primary/5 hover:-translate-y-2 overflow-hidden">
                <div className={`relative flex aspect-[4/3] items-center justify-center bg-gradient-to-br ${artist.color} overflow-hidden`}>
                  <motion.div
                    animate={{ rotate: 360 }}
                    transition={{ repeat: Infinity, duration: 20, ease: "linear" }}
                    className="absolute h-40 w-40 rounded-full border border-primary/10"
                  />
                  <motion.div
                    animate={{ rotate: -360 }}
                    transition={{ repeat: Infinity, duration: 15, ease: "linear" }}
                    className="absolute h-28 w-28 rounded-full border border-primary/20"
                  />
                  <div className="relative flex h-24 w-24 items-center justify-center rounded-full bg-background/50 backdrop-blur-sm border border-primary/20 transition-all duration-300 group-hover:scale-110 group-hover:border-primary/40">
                    <Disc3 className="h-10 w-10 text-muted-foreground/40 transition-colors group-hover:text-primary/60" />
                  </div>
                </div>
                <div className="p-6">
                  <div className="flex items-center justify-between">
                    <h3 className="text-xl font-bold transition-colors group-hover:text-primary">
                      {artist.name}
                    </h3>
                    <Badge variant="secondary" className="text-xs">
                      {artist.genre}
                    </Badge>
                  </div>
                  <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
                    {artist.bio}
                  </p>
                  <div className="mt-4 flex items-center gap-2">
                    <div className="h-1.5 w-1.5 rounded-full bg-primary" />
                    <span className="text-xs text-primary">{artist.stats}</span>
                  </div>
                  <div className="mt-5 flex flex-wrap gap-2">
                    {artist.spotify && (
                      <a href={artist.spotify} target="_blank" rel="noopener noreferrer">
                        <Button variant="outline" size="sm" className="transition-all hover:bg-green-500/10 hover:border-green-500/30">
                          <Globe className="mr-1.5 h-3.5 w-3.5" />
                          Spotify
                        </Button>
                      </a>
                    )}
                    {artist.appleMusic && (
                      <a href={artist.appleMusic} target="_blank" rel="noopener noreferrer">
                        <Button variant="outline" size="sm" className="transition-all hover:bg-pink-500/10 hover:border-pink-500/30">
                          <Headphones className="mr-1.5 h-3.5 w-3.5" />
                          Apple Music
                        </Button>
                      </a>
                    )}
                    {artist.boomplay && (
                      <a href={artist.boomplay} target="_blank" rel="noopener noreferrer">
                        <Button variant="outline" size="sm" className="transition-all hover:bg-blue-500/10 hover:border-blue-500/30">
                          Boomplay
                        </Button>
                      </a>
                    )}
                    {artist.audiomack && (
                      <a href={artist.audiomack} target="_blank" rel="noopener noreferrer">
                        <Button variant="outline" size="sm" className="transition-all hover:bg-orange-500/10 hover:border-orange-500/30">
                          Audiomack
                        </Button>
                      </a>
                    )}
                  </div>
                </div>
              </Card>
            </StaggerItem>
          ))}
        </StaggerGrid>
      </div>
    </div>
  );
}
