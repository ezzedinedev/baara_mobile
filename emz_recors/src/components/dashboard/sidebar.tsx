"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  MessageSquare,
  Music,
  Users,
  Settings,
  LogOut,
} from "lucide-react";

const navItems = [
  {
    href: "/dashboard",
    label: "Vue d'ensemble",
    icon: LayoutDashboard,
  },
  {
    href: "/dashboard/messages",
    label: "Messages",
    icon: MessageSquare,
  },
  {
    href: "/dashboard/demos",
    label: "Démos",
    icon: Music,
  },
  {
    href: "/dashboard/artists",
    label: "Artistes",
    icon: Users,
  },
  {
    href: "/dashboard/settings",
    label: "Paramètres",
    icon: Settings,
  },
];

export function DashboardSidebar() {
  const pathname = usePathname();

  return (
    <aside className="fixed left-0 top-0 z-40 h-screen w-64 border-r border-border/40 bg-sidebar">
      <div className="flex h-16 items-center gap-2 border-b border-border/40 px-6">
        <div className="h-6 w-6 rounded-full bg-primary" />
        <span className="text-sm font-bold">
          EMZ<span className="text-primary"> RECORD</span>
        </span>
      </div>

      <nav className="space-y-1 p-4">
        {navItems.map((item) => {
          const isActive =
            item.href === "/dashboard"
              ? pathname === "/dashboard"
              : pathname.startsWith(item.href);

          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${
                isActive
                  ? "bg-primary/10 text-primary"
                  : "text-muted-foreground hover:bg-muted/50 hover:text-foreground"
              }`}
            >
              <item.icon className="h-4 w-4" />
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="absolute bottom-4 left-0 right-0 px-4">
        <Link
          href="/"
          className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-muted-foreground transition-colors hover:bg-muted/50 hover:text-foreground"
        >
          <LogOut className="h-4 w-4" />
          Retour au site
        </Link>
      </div>
    </aside>
  );
}
