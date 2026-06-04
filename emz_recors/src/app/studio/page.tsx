"use client";

import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Mic, Music, Waves, Sliders, Sparkles, ArrowRight, Headphones, Disc3 } from "lucide-react";
import Link from "next/link";
import { motion } from "framer-motion";
import { AnimatedSection, StaggerGrid, StaggerItem } from "@/components/ui/animations/animated-section";
import { AnimatedGradient } from "@/components/ui/animations/animated-gradient";

const services = [
  {
    icon: Mic,
    title: "Enregistrement",
    description: "Cabine insonorisée, micros studio professionnels, préamplis haute qualité.",
    color: "from-blue-500/10 to-blue-500/5",
  },
  {
    icon: Sliders,
    title: "Mixage",
    description: "Équilibrage, spatialisation, traitement dynamique pour un son professionnel.",
    color: "from-purple-500/10 to-purple-500/5",
  },
  {
    icon: Waves,
    title: "Mastering",
    description: "Finalisation et optimisation de vos pistes pour toutes les plateformes.",
    color: "from-amber-500/10 to-amber-500/5",
  },
  {
    icon: Sparkles,
    title: "Réalisation artistique",
    description: "Direction artistique complète : arrangements, composition, production.",
    color: "from-green-500/10 to-green-500/5",
  },
];

const team = [
  {
    name: "Marez on the track",
    role: "Ingénieur du son & Beatmaker",
    bio: "Chef d'orchestre technique du label. Mixage, mastering, beatmaking – Marez façonne l'identité sonore d'EMZ RECORD.",
    color: "from-amber-500/20 to-orange-500/10",
  },
];

export default function StudioPage() {
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
              <Headphones className="mr-1.5 h-3.5 w-3.5" />
              L&apos;envers du décor
            </Badge>
          </motion.div>
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
            Studio & <span className="text-gradient">Équipe</span>
          </h1>
          <p className="mx-auto mt-4 max-w-2xl text-lg text-muted-foreground">
            Des infrastructures professionnelles et une équipe technique
            d&apos;exception pour donner vie à vos projets.
          </p>
        </motion.div>

        {/* Équipe */}
        <AnimatedSection className="mb-20">
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
          >
            <h2 className="mb-8 text-2xl font-bold flex items-center gap-3">
              <span className="h-8 w-1 rounded-full bg-primary" />
              L&apos;équipe <span className="text-gradient">technique</span>
            </h2>
          </motion.div>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {team.map((member) => (
              <motion.div
                key={member.name}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6 }}
              >
                <Card className="group border-border/40 bg-card/50 backdrop-blur overflow-hidden transition-all duration-500 hover:border-primary/30 hover:shadow-xl hover:shadow-primary/5 hover:-translate-y-1">
                  <div className={`relative flex aspect-square items-center justify-center bg-gradient-to-br ${member.color} overflow-hidden`}>
                    <motion.div
                      animate={{ scale: [1, 1.1, 1] }}
                      transition={{ repeat: Infinity, duration: 6, ease: "easeInOut" }}
                      className="absolute h-48 w-48 rounded-full border border-primary/10"
                    />
                    <div className="relative flex h-24 w-24 items-center justify-center rounded-full bg-background/50 backdrop-blur border border-primary/20 transition-all duration-300 group-hover:scale-110">
                      <Disc3 className="h-12 w-12 text-muted-foreground/30" />
                    </div>
                  </div>
                  <div className="p-6">
                    <Badge variant="secondary" className="mb-3">
                      {member.role}
                    </Badge>
                    <h3 className="text-xl font-bold transition-colors group-hover:text-primary">
                      {member.name}
                    </h3>
                    <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                      {member.bio}
                    </p>
                  </div>
                </Card>
              </motion.div>
            ))}
          </div>
        </AnimatedSection>

        {/* Services */}
        <AnimatedSection>
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
          >
            <h2 className="mb-8 text-2xl font-bold flex items-center gap-3">
              <span className="h-8 w-1 rounded-full bg-primary" />
              Nos <span className="text-gradient">services</span>
            </h2>
          </motion.div>

          <StaggerGrid className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {services.map((service) => (
              <StaggerItem key={service.title}>
                <Card className="group h-full border-border/40 bg-card/50 backdrop-blur transition-all duration-300 hover:border-primary/30 hover:shadow-lg hover:shadow-primary/5 hover:-translate-y-1 overflow-hidden">
                  <div className={`absolute inset-0 bg-gradient-to-br ${service.color} opacity-0 transition-opacity duration-300 group-hover:opacity-100`} />
                  <div className="relative p-6">
                    <motion.div
                      whileHover={{ rotate: 10, scale: 1.1 }}
                      className="flex h-12 w-12 items-center justify-center rounded-lg bg-primary/10 transition-all group-hover:bg-primary/20"
                    >
                      <service.icon className="h-6 w-6 text-primary transition-transform" />
                    </motion.div>
                    <h3 className="mt-4 text-lg font-semibold transition-colors group-hover:text-primary">
                      {service.title}
                    </h3>
                    <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                      {service.description}
                    </p>
                  </div>
                </Card>
              </StaggerItem>
            ))}
          </StaggerGrid>
        </AnimatedSection>

        {/* CTA */}
        <AnimatedSection className="mt-16">
          <motion.div
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
          >
            <Card className="relative overflow-hidden border-border/40 bg-gradient-to-br from-primary/10 via-background to-background p-10 text-center transition-all duration-500 hover:border-primary/30">
              <div className="absolute top-1/2 left-1/2 h-60 w-60 -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary/10 blur-3xl" />
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
                <h3 className="text-2xl font-bold">
                  Vous voulez travailler avec nous ?
                </h3>
                <p className="mt-3 text-muted-foreground">
                  Que vous soyez artiste ou producteur, contactez-nous pour
                  réserver une session au studio.
                </p>
                <Link href="/contact">
                  <Button size="lg" className="mt-6 group">
                    Réserver une session
                    <ArrowRight className="ml-2 h-4 w-4 transition-transform group-hover:translate-x-1" />
                  </Button>
                </Link>
              </div>
            </Card>
          </motion.div>
        </AnimatedSection>
      </div>
    </div>
  );
}
