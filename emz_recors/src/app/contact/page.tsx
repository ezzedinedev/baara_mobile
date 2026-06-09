"use client";

import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Mail, Music, AlertTriangle, Send, Sparkles } from "lucide-react";
import { motion } from "framer-motion";
import { AnimatedGradient } from "@/components/ui/animations/animated-gradient";
import { toast } from "sonner";
import { useState } from "react";

export default function ContactPage() {
  const [contactType, setContactType] = useState("prestation");

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
              Restons en contact
            </Badge>
          </motion.div>
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
            Contact & <span className="text-gradient">Démos</span>
          </h1>
          <p className="mx-auto mt-4 max-w-2xl text-lg text-muted-foreground">
            Une question, une demande de prestation ou une maquette à soumettre ?
            On écoute tout.
          </p>
        </motion.div>

        <div className="grid gap-12 lg:grid-cols-2">
          {/* Formulaire de contact */}
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3, duration: 0.6 }}
          >
            <Card className="group border-border/40 bg-card/50 backdrop-blur p-8 transition-all duration-500 hover:border-primary/30 hover:shadow-xl hover:shadow-primary/5">
              <div className="mb-6 flex items-center gap-3">
                <motion.div
                  whileHover={{ rotate: 10, scale: 1.1 }}
                  className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10"
                >
                  <Mail className="h-5 w-5 text-primary" />
                </motion.div>
                <h2 className="text-xl font-bold">Nous écrire</h2>
              </div>

              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  toast.success("Message envoyé avec succès !");
                }}
                className="space-y-5"
              >
                <div className="grid gap-4 sm:grid-cols-2">
                  <motion.div
                    className="space-y-2"
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.4 }}
                  >
                    <Label htmlFor="name">Nom complet</Label>
                    <Input id="name" placeholder="Votre nom" required className="transition-all duration-300 focus:ring-2 focus:ring-primary/30" />
                  </motion.div>
                  <motion.div
                    className="space-y-2"
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.45 }}
                  >
                    <Label htmlFor="email">Email</Label>
                    <Input id="email" type="email" placeholder="vous@email.com" required className="transition-all duration-300 focus:ring-2 focus:ring-primary/30" />
                  </motion.div>
                </div>

                <motion.div
                  className="grid gap-4 sm:grid-cols-2"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.5 }}
                >
                  <div className="space-y-2">
                    <Label htmlFor="phone">Téléphone (optionnel)</Label>
                    <Input id="phone" type="tel" placeholder="+225 00 00 00 00" className="transition-all duration-300 focus:ring-2 focus:ring-primary/30" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="subject">Sujet</Label>
                    <Select value={contactType} onValueChange={(v: string | null) => v && setContactType(v)}>
                      <SelectTrigger id="subject">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="studio">Location studio</SelectItem>
                        <SelectItem value="prestation">Prestation (mix/master)</SelectItem>
                        <SelectItem value="demo">Envoi de démo</SelectItem>
                        <SelectItem value="autre">Autre</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </motion.div>

                <motion.div
                  className="space-y-2"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.55 }}
                >
                  <Label htmlFor="message">Message</Label>
                  <Textarea id="message" placeholder="Décrivez votre demande..." className="min-h-[120px] transition-all duration-300 focus:ring-2 focus:ring-primary/30" required />
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.6 }}
                >
                  <Button type="submit" className="w-full group">
                    <Send className="mr-2 h-4 w-4 transition-transform group-hover:translate-x-0.5" />
                    Envoyer le message
                  </Button>
                </motion.div>
              </form>
            </Card>
          </motion.div>

          {/* Section Démos */}
          <motion.div
            initial={{ opacity: 0, x: 30 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.4, duration: 0.6 }}
            className="space-y-8"
          >
            <Card className="group border-border/40 bg-card/50 backdrop-blur p-8 transition-all duration-500 hover:border-primary/30 hover:shadow-xl hover:shadow-primary/5">
              <div className="mb-6 flex items-center gap-3">
                <motion.div
                  whileHover={{ rotate: 10, scale: 1.1 }}
                  className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10"
                >
                  <Music className="h-5 w-5 text-primary" />
                </motion.div>
                <h2 className="text-xl font-bold">Soumettre une démo</h2>
              </div>

              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  toast.success("Démo soumise avec succès !");
                }}
                className="space-y-5"
              >
                <div className="grid gap-4 sm:grid-cols-2">
                  <div className="space-y-2">
                    <Label htmlFor="artistName">Nom d&apos;artiste</Label>
                    <Input id="artistName" placeholder="Votre nom de scène" required className="transition-all duration-300 focus:ring-2 focus:ring-primary/30" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="demoEmail">Email</Label>
                    <Input id="demoEmail" type="email" placeholder="vous@email.com" required className="transition-all duration-300 focus:ring-2 focus:ring-primary/30" />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="demoLink">Lien d&apos;écoute (SoundCloud privé / Dropbox)</Label>
                  <Input id="demoLink" placeholder="https://soundcloud.com/..." required className="transition-all duration-300 focus:ring-2 focus:ring-primary/30" />
                </div>

                <div className="grid gap-4 sm:grid-cols-2">
                  <div className="space-y-2">
                    <Label htmlFor="genre">Genre musical</Label>
                    <Select>
                      <SelectTrigger id="genre">
                        <SelectValue placeholder="Sélectionner" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="afro">Afro Beat</SelectItem>
                        <SelectItem value="rap">Rap / Hip-Hop</SelectItem>
                        <SelectItem value="rnb">RnB</SelectItem>
                        <SelectItem value="pop">Pop</SelectItem>
                        <SelectItem value="autre">Autre</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="availability">Disponible au mix ?</Label>
                    <Select>
                      <SelectTrigger id="availability">
                        <SelectValue placeholder="Sélectionner" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="yes">Oui, stems disponibles</SelectItem>
                        <SelectItem value="partial">Partiellement</SelectItem>
                        <SelectItem value="no">Non, piste finale uniquement</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="demoDescription">Parle-nous de ton projet</Label>
                  <Textarea id="demoDescription" placeholder="Inspirations, influences, ce que tu recherches..." className="min-h-[100px] transition-all duration-300 focus:ring-2 focus:ring-primary/30" />
                </div>

                <Button type="submit" className="w-full group">
                  <Send className="mr-2 h-4 w-4 transition-transform group-hover:translate-x-0.5" />
                  Soumettre la démo
                </Button>
              </form>
            </Card>

            {/* Règles */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.6 }}
            >
              <Card className="border-amber-500/20 bg-amber-500/5 p-6 transition-all duration-300 hover:border-amber-500/40 hover:shadow-lg hover:shadow-amber-500/5">
                <div className="flex gap-3">
                  <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-amber-400" />
                  <div>
                    <h3 className="font-semibold text-amber-400">
                      Règles d&apos;envoi des démos
                    </h3>
                    <ul className="mt-2 space-y-1 text-sm text-muted-foreground">
                      <li className="flex items-center gap-2">
                        <span className="h-1 w-1 rounded-full bg-amber-400" />
                        Envoyez uniquement des liens d&apos;écoute (SoundCloud privé, Dropbox)
                      </li>
                      <li className="flex items-center gap-2">
                        <span className="h-1 w-1 rounded-full bg-amber-400" />
                        Aucun fichier MP3 joint par mail ne sera téléchargé
                      </li>
                      <li className="flex items-center gap-2">
                        <span className="h-1 w-1 rounded-full bg-amber-400" />
                        Les maquettes non sollicitées ne seront pas retournées
                      </li>
                      <li className="flex items-center gap-2">
                        <span className="h-1 w-1 rounded-full bg-amber-400" />
                        Délai de réponse : 2 à 4 semaines
                      </li>
                    </ul>
                  </div>
                </div>
              </Card>
            </motion.div>
          </motion.div>
        </div>
      </div>
    </div>
  );
}
