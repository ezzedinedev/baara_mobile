"use client";

import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Search, Mail, MailOpen, CheckCheck } from "lucide-react";
import { useState } from "react";

const initialMessages = [
  {
    id: "1",
    name: "Jean Kouadio",
    email: "jean@email.com",
    subject: "Location studio",
    type: "studio",
    status: "unread" as const,
    message:
      "Bonjour, je souhaiterais réserver le studio pour une session d'enregistrement la semaine prochaine. Pouvez-vous me donner vos disponibilités et tarifs ?",
    createdAt: "2026-06-01T14:30:00",
  },
  {
    id: "2",
    name: "Sarah Boli",
    email: "sarah@email.com",
    subject: "Prestation mixage",
    type: "prestation",
    status: "read" as const,
    message:
      "Salut ! J'aimerais faire mixer et masteriser mon EP de 5 titres. J'ai les stems prêts. Merci de me contacter pour les délais et le devis.",
    createdAt: "2026-05-30T10:00:00",
  },
  {
    id: "3",
    name: "Mike Oka",
    email: "mike@email.com",
    subject: "Proposition de collaboration",
    type: "autre",
    status: "replied" as const,
    message:
      "Je suis beatmaker basé à Paris, j'aimerais proposer quelques instrumentales à votre label.",
    createdAt: "2026-05-28T08:15:00",
  },
];

export default function MessagesPage() {
  const [messages, setMessages] = useState(initialMessages);
  const [selected, setSelected] = useState<string | null>(null);
  const [search, setSearch] = useState("");

  const filtered = messages.filter(
    (m) =>
      m.name.toLowerCase().includes(search.toLowerCase()) ||
      m.subject.toLowerCase().includes(search.toLowerCase())
  );

  const selectedMsg = messages.find((m) => m.id === selected);

  const markRead = (id: string) => {
    setMessages((prev) =>
      prev.map((m) => (m.id === id ? { ...m, status: "read" as const } : m))
    );
  };

  return (
    <div className="flex h-full">
      <div className="w-96 shrink-0 border-r border-border/40 p-6">
        <div className="mb-6">
          <h1 className="text-xl font-bold">Messages</h1>
          <p className="text-sm text-muted-foreground">
            {messages.filter((m) => m.status === "unread").length} non lus
          </p>
        </div>

        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Rechercher..."
            className="pl-9"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div className="space-y-2">
          {filtered.map((msg) => (
            <button
              key={msg.id}
              onClick={() => {
                setSelected(msg.id);
                if (msg.status === "unread") markRead(msg.id);
              }}
              className={`w-full rounded-lg border border-border/40 p-3 text-left transition-colors hover:bg-muted/50 ${
                selected === msg.id ? "border-primary/50 bg-primary/5" : ""
              } ${msg.status === "unread" ? "border-l-2 border-l-primary" : ""}`}
            >
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">{msg.name}</span>
                <div className="flex items-center gap-1">
                  {msg.status === "unread" && (
                    <Mail className="h-3 w-3 text-primary" />
                  )}
                  {msg.status === "read" && (
                    <MailOpen className="h-3 w-3 text-muted-foreground" />
                  )}
                  {msg.status === "replied" && (
                    <CheckCheck className="h-3 w-3 text-green-400" />
                  )}
                  <span className="text-xs text-muted-foreground">
                    {new Date(msg.createdAt).toLocaleDateString("fr-FR", {
                      day: "numeric",
                      month: "short",
                    })}
                  </span>
                </div>
              </div>
              <p className="mt-1 truncate text-xs text-muted-foreground">
                {msg.subject}
              </p>
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 p-6">
        {selectedMsg ? (
          <div>
            <div className="mb-6 flex items-start justify-between">
              <div>
                <h2 className="text-lg font-bold">{selectedMsg.name}</h2>
                <p className="text-sm text-muted-foreground">
                  {selectedMsg.email}
                </p>
              </div>
              <Badge variant="secondary">
                {selectedMsg.type}
              </Badge>
            </div>

            <div className="mb-4">
              <h3 className="text-sm font-medium text-muted-foreground">
                Sujet
              </h3>
              <p className="font-medium">{selectedMsg.subject}</p>
            </div>

            <Card className="border-border/40 bg-card/50 p-4">
              <p className="text-sm leading-relaxed">{selectedMsg.message}</p>
            </Card>

            <div className="mt-6">
              <h3 className="mb-2 text-sm font-medium text-muted-foreground">
                Répondre
              </h3>
              <textarea
                className="w-full rounded-lg border border-border/40 bg-background p-3 text-sm"
                rows={4}
                placeholder="Écrivez votre réponse..."
              />
              <Button size="sm" className="mt-2">
                Envoyer la réponse
              </Button>
            </div>
          </div>
        ) : (
          <div className="flex h-full items-center justify-center">
            <div className="text-center">
              <Mail className="mx-auto h-12 w-12 text-muted-foreground/30" />
              <p className="mt-4 text-sm text-muted-foreground">
                Sélectionnez un message
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
