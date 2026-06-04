"use client";

import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ArrowRight, Play, Music, Headphones, Sparkles, Radio, TrendingUp, Star } from "lucide-react";
import { motion } from "framer-motion";
import { AnimatedSection, StaggerGrid, StaggerItem } from "@/components/ui/animations/animated-section";
import { AnimatedGradient } from "@/components/ui/animations/animated-gradient";

const news = [
  {
    title: "Nouvelle signature : Kemèl rejoint EMZ RECORD",
    date: "Mai 2026",
    category: "Signature",
    description: "Nous sommes fiers d'accueillir Kemèl, artiste aux sonorités afro-urbaines uniques.",
    icon: Star,
  },
  {
    title: "Sortie du single 'Fuego' de Kayna",
    date: "Avril 2026",
    category: "Sortie",
    description: "Le nouveau single est disponible sur toutes les plateformes de streaming.",
    icon: Music,
  },
  {
    title: "EMZ RECORD au Festival des Musiques Urbaines",
    date: "Mars 2026",
    category: "Événement",
    description: "Le label était présent au FMU 2026 avec un showcase exclusif.",
    icon: Radio,
  },
];

export default function HomePage() {
  return (
    <div className="relative">
      <AnimatedGradient />

      {/* Hero */}
      <section className="relative flex min-h-screen items-center justify-center overflow-hidden pt-16">
        <div className="absolute inset-0 bg-gradient-to-b from-primary/5 via-transparent to-background" />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--primary)_0%,_transparent_70%)] opacity-20" />

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1.5 }}
          className="absolute inset-0"
        >
          <div className="absolute top-1/4 left-1/4 h-64 w-64 rounded-full bg-primary/10 blur-[100px]" />
          <div className="absolute bottom-1/4 right-1/4 h-48 w-48 rounded-full bg-primary/5 blur-[80px]" />
        </motion.div>

        <div className="relative z-10 mx-auto max-w-4xl px-4 text-center">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.2, duration: 0.5 }}
          >
            <Badge variant="outline" className="mb-6 border-primary/30 text-primary animate-pulse-glow">
              <Sparkles className="mr-1.5 h-3.5 w-3.5" />
              Label de musique & Studio
            </Badge>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4, duration: 0.8, ease: [0.25, 0.1, 0.25, 1] }}
            className="text-5xl font-bold tracking-tight sm:text-6xl lg:text-7xl"
          >
            Produire l&apos;excellence,
            <br />
            <span className="text-gradient">propulser les talents</span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6, duration: 0.6 }}
            className="mx-auto mt-6 max-w-2xl text-lg text-muted-foreground"
          >
            EMZ RECORD est un label de musique basé à Abidjan, dédié à la
            production, la promotion et l&apos;accompagnement d&apos;artistes
            d&apos;exception.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.8, duration: 0.6 }}
            className="mt-8 flex flex-wrap items-center justify-center gap-4"
          >
            <Link href="/roster">
              <Button size="lg" className="group relative overflow-hidden">
                <span className="relative z-10 flex items-center">
                  Découvrir les artistes
                  <ArrowRight className="ml-2 h-4 w-4 transition-transform group-hover:translate-x-1" />
                </span>
              </Button>
            </Link>
            <Link href="/contact">
              <Button variant="outline" size="lg" className="group">
                <Headphones className="mr-2 h-4 w-4 transition-transform group-hover:scale-110" />
                Contacter le label
              </Button>
            </Link>
          </motion.div>

          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.2, duration: 1 }}
            className="mt-16 flex items-center justify-center gap-8 text-sm text-muted-foreground"
          >
            {["3 Artistes", "50+ Titres", "1M+ Streams"].map((stat) => (
              <div key={stat} className="flex items-center gap-2">
                <TrendingUp className="h-4 w-4 text-primary" />
                {stat}
              </div>
            ))}
          </motion.div>
        </div>

        <motion.div
          animate={{ y: [0, 10, 0] }}
          transition={{ repeat: Infinity, duration: 3, ease: "easeInOut" }}
          className="absolute bottom-8 left-1/2 -translate-x-1/2"
        >
          <div className="h-12 w-6 rounded-full border-2 border-border/40 flex items-start justify-center p-1.5">
            <motion.div
              animate={{ y: [0, 12, 0] }}
              transition={{ repeat: Infinity, duration: 2, ease: "easeInOut" }}
              className="h-2 w-1.5 rounded-full bg-primary"
            />
          </div>
        </motion.div>
      </section>

      {/* Projet Phare */}
      <AnimatedSection className="relative mx-auto max-w-7xl px-4 py-24 sm:px-6 lg:px-8">
        <div className="mb-12 text-center">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
          >
            <Badge variant="outline" className="mb-4 border-primary/30 text-primary">
              Dernière sortie
            </Badge>
          </motion.div>
          <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Projet <span className="text-gradient">Phare</span>
          </h2>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7 }}
        >
          <Card className="group relative overflow-hidden border-border/40 bg-card/50 backdrop-blur transition-all duration-500 hover:border-primary/30 hover:shadow-xl hover:shadow-primary/5">
            <div className="absolute inset-0 bg-gradient-to-r from-primary/5 via-transparent to-transparent opacity-0 transition-opacity duration-500 group-hover:opacity-100" />
            <div className="relative grid md:grid-cols-2">
              <div className="flex flex-col justify-center p-8 md:p-12">
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: 0.2 }}
                >
                  <Badge className="mb-4 w-fit bg-primary text-primary-foreground animate-pulse-glow">
                    Nouveau single
                  </Badge>
                  <h3 className="text-2xl font-bold sm:text-3xl">
                    &laquo; Fuego &raquo;
                  </h3>
                  <p className="mt-2 text-lg text-muted-foreground">
                    Kayna feat. Marez on the track
                  </p>
                  <p className="mt-4 leading-relaxed text-muted-foreground">
                    Un titre afro-dancefloor produit par Marez on the track, mixé
                    et masterisé au EMZ Studio. Disponible sur toutes les
                    plateformes.
                  </p>
                  <div className="mt-6 flex flex-wrap gap-3">
                    <Button size="sm" className="group/btn">
                      <Play className="mr-2 h-4 w-4 transition-transform group-hover/btn:scale-110" />
                      Écouter maintenant
                    </Button>
                    <Button variant="outline" size="sm" className="group/btn">
                      <Music className="mr-2 h-4 w-4 transition-transform group-hover/btn:scale-110" />
                      Voir le clip
                    </Button>
                  </div>
                </motion.div>
              </div>
              <div className="relative flex items-center justify-center overflow-hidden p-8 md:p-12">
                <motion.div
                  animate={{ scale: [1, 1.05, 1], rotate: [0, 5, 0] }}
                  transition={{ repeat: Infinity, duration: 8, ease: "easeInOut" }}
                  className="relative"
                >
                  <div className="h-64 w-64 rounded-full border-2 border-primary/30 bg-gradient-to-br from-primary/20 via-primary/10 to-transparent" />
                  <div className="absolute inset-4 rounded-full border border-primary/20" />
                  <div className="absolute inset-8 rounded-full border border-primary/10" />
                  <div className="absolute inset-0 flex items-center justify-center">
                    <Play className="h-12 w-12 text-primary/60" />
                  </div>
                </motion.div>
              </div>
            </div>
          </Card>
        </motion.div>
      </AnimatedSection>

      {/* Actualités */}
      <AnimatedSection className="relative mx-auto max-w-7xl px-4 py-24 sm:px-6 lg:px-8">
        <div className="mb-12 text-center">
          <Badge variant="outline" className="mb-4 border-primary/30 text-primary">
            Vie du label
          </Badge>
          <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Actualités <span className="text-gradient">Récentes</span>
          </h2>
        </div>

        <StaggerGrid className="grid gap-6 md:grid-cols-3">
          {news.map((item) => (
            <StaggerItem key={item.title}>
              <Card className="group h-full border-border/40 bg-card/50 backdrop-blur transition-all duration-300 hover:border-primary/30 hover:shadow-lg hover:shadow-primary/5 hover:-translate-y-1">
                <div className="p-6">
                  <div className="flex items-center justify-between">
                    <Badge variant="secondary" className="text-xs">
                      {item.category}
                    </Badge>
                    <span className="text-xs text-muted-foreground">
                      {item.date}
                    </span>
                  </div>
                  <div className="mt-4 flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                    <item.icon className="h-5 w-5 text-primary" />
                  </div>
                  <h3 className="mt-4 text-lg font-semibold transition-colors group-hover:text-primary">
                    {item.title}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                    {item.description}
                  </p>
                </div>
              </Card>
            </StaggerItem>
          ))}
        </StaggerGrid>
      </AnimatedSection>

      {/* CTA */}
      <AnimatedSection className="relative mx-auto max-w-7xl px-4 pb-24 sm:px-6 lg:px-8">
        <motion.div
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
        >
          <Card className="relative overflow-hidden border-border/40 bg-gradient-to-br from-primary/10 via-background to-background p-12 text-center transition-all duration-500 hover:border-primary/30">
            <div className="absolute -top-20 -right-20 h-40 w-40 rounded-full bg-primary/20 blur-3xl" />
            <div className="absolute -bottom-20 -left-20 h-40 w-40 rounded-full bg-primary/10 blur-3xl" />
            <div className="relative">
              <motion.div
                initial={{ scale: 0 }}
                whileInView={{ scale: 1 }}
                viewport={{ once: true }}
                transition={{ type: "spring", stiffness: 200, delay: 0.2 }}
                className="mx-auto mb-6 flex h-16 w-16 items-center justify-center rounded-full bg-primary/10"
              >
                <Headphones className="h-8 w-8 text-primary" />
              </motion.div>
              <h2 className="text-3xl font-bold tracking-tight">
                Vous êtes un artiste ?
              </h2>
              <p className="mx-auto mt-4 max-w-xl text-muted-foreground">
                Envoyez-nous votre maquette. Notre équipe artistique étudie chaque
                proposition avec attention.
              </p>
              <Link href="/contact">
                <Button size="lg" className="mt-8 group">
                  Soumettre une démo
                  <ArrowRight className="ml-2 h-4 w-4 transition-transform group-hover:translate-x-1" />
                </Button>
              </Link>
            </div>
          </Card>
        </motion.div>
      </AnimatedSection>
    </div>
  );
}
