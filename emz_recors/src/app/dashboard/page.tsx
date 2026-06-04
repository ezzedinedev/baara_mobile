"use client";

import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  MessageSquare,
  Music,
  Users,
  TrendingUp,
  Calendar,
} from "lucide-react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  ResponsiveContainer,
} from "recharts";

const stats = [
  {
    label: "Messages non lus",
    value: "12",
    icon: MessageSquare,
    change: "+3 cette semaine",
  },
  {
    label: "Démos en attente",
    value: "8",
    icon: Music,
    change: "+2 cette semaine",
  },
  {
    label: "Artistes au roster",
    value: "3",
    icon: Users,
    change: "+1 ce mois",
  },
  {
    label: "Taux de réponse",
    value: "94%",
    icon: TrendingUp,
    change: "+2% vs dernier mois",
  },
];

const chartData = [
  { month: "Jan", messages: 8, demos: 4 },
  { month: "Fév", messages: 12, demos: 6 },
  { month: "Mar", messages: 10, demos: 5 },
  { month: "Avr", messages: 15, demos: 8 },
  { month: "Mai", messages: 18, demos: 7 },
  { month: "Juin", messages: 12, demos: 8 },
];

export default function DashboardPage() {
  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold tracking-tight">
          Vue d&apos;ensemble
        </h1>
        <p className="text-muted-foreground">
          Bienvenue sur le tableau de bord EMZ RECORD.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <Card
            key={stat.label}
            className="border-border/40 bg-card/50 backdrop-blur p-6"
          >
            <div className="flex items-center justify-between">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                <stat.icon className="h-5 w-5 text-primary" />
              </div>
            </div>
            <p className="mt-4 text-2xl font-bold">{stat.value}</p>
            <p className="text-sm text-muted-foreground">{stat.label}</p>
            <p className="mt-1 text-xs text-primary">{stat.change}</p>
          </Card>
        ))}
      </div>

      <div className="mt-8 grid gap-6 lg:grid-cols-2">
        <Card className="border-border/40 bg-card/50 backdrop-blur p-6">
          <h3 className="mb-6 text-lg font-semibold">
            Activité mensuelle
          </h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-border/50" />
                <XAxis
                  dataKey="month"
                  className="text-xs text-muted-foreground"
                />
                <YAxis className="text-xs text-muted-foreground" />
                <Bar
                  dataKey="messages"
                  fill="oklch(0.78 0.12 85)"
                  radius={[4, 4, 0, 0]}
                  name="Messages"
                />
                <Bar
                  dataKey="demos"
                  fill="oklch(0.55 0.1 270)"
                  radius={[4, 4, 0, 0]}
                  name="Démos"
                />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card className="border-border/40 bg-card/50 backdrop-blur p-6">
          <h3 className="mb-6 text-lg font-semibold">
            Activités récentes
          </h3>
          <div className="space-y-4">
            {[
              {
                icon: MessageSquare,
                text: "Nouveau message de Kayna",
                time: "Il y a 2h",
                color: "text-primary",
              },
              {
                icon: Music,
                text: "Démo reçue de Artiste X",
                time: "Il y a 5h",
                color: "text-blue-400",
              },
              {
                icon: Users,
                text: "Kemèl a rejoint le roster",
                time: "Hier",
                color: "text-green-400",
              },
              {
                icon: MessageSquare,
                text: "Demande de location studio",
                time: "Hier",
                color: "text-primary",
              },
            ].map((activity) => (
              <div
                key={activity.text}
                className="flex items-center gap-3 rounded-lg border border-border/40 p-3"
              >
                <activity.icon
                  className={`h-4 w-4 shrink-0 ${activity.color}`}
                />
                <div className="flex-1">
                  <p className="text-sm">{activity.text}</p>
                </div>
                <span className="text-xs text-muted-foreground">
                  {activity.time}
                </span>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}
