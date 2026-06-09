"use client";

import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";

export default function SettingsPage() {
  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold tracking-tight">Paramètres</h1>
        <p className="text-muted-foreground">
          Gérez les informations du label.
        </p>
      </div>

      <div className="max-w-2xl space-y-8">
        <Card className="border-border/40 bg-card/50 backdrop-blur p-6">
          <h2 className="mb-6 text-lg font-semibold">
            Informations générales
          </h2>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              toast.success("Paramètres mis à jour");
            }}
            className="space-y-5"
          >
            <div className="space-y-2">
              <Label htmlFor="name">Nom du label</Label>
              <Input id="name" defaultValue="EMZ RECORD" />
            </div>

            <div className="space-y-2">
              <Label htmlFor="tagline">Slogan</Label>
              <Input
                id="tagline"
                defaultValue="Produire l'excellence, propulser les talents"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="email">Email de contact</Label>
              <Input id="email" type="email" defaultValue="contact@emzrecord.com" />
            </div>

            <div className="space-y-2">
              <Label htmlFor="bio">Description</Label>
              <Textarea
                id="bio"
                defaultValue="Label de musique basé à Abidjan..."
                className="min-h-[100px]"
              />
            </div>

            <Button type="submit">Enregistrer</Button>
          </form>
        </Card>

        <Card className="border-border/40 bg-card/50 backdrop-blur p-6">
          <h2 className="mb-2 text-lg font-semibold text-red-400">
            Zone dangereuse
          </h2>
          <p className="mb-6 text-sm text-muted-foreground">
            Actions irréversibles.
          </p>
          <Button variant="destructive">Exporter toutes les données</Button>
        </Card>
      </div>
    </div>
  );
}
