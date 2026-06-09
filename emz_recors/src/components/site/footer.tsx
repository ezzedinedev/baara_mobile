"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export function SiteFooter() {
  const pathname = usePathname();
  if (pathname.startsWith("/dashboard") || pathname.startsWith("/login")) return null;
  return (
    <footer className="border-t border-border/40 bg-background">
      <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
        <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <div className="flex items-center gap-2">
              <div className="h-6 w-6 rounded-full bg-primary" />
              <span className="text-sm font-bold">
                EMZ<span className="text-primary"> RECORD</span>
              </span>
            </div>
            <p className="mt-3 text-sm text-muted-foreground">
              Produire l&apos;excellence, propulser les talents.
            </p>
          </div>

          <div>
            <h3 className="text-sm font-semibold">Navigation</h3>
            <ul className="mt-3 space-y-2">
              {[
                { href: "/", label: "Accueil" },
                { href: "/roster", label: "Roster" },
                { href: "/studio", label: "Studio" },
                { href: "/contact", label: "Contact" },
              ].map((link) => (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className="text-sm text-muted-foreground transition-colors hover:text-primary"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="text-sm font-semibold">Suivez-nous</h3>
            <ul className="mt-3 space-y-2">
              {["Instagram", "YouTube", "Twitter/X", "TikTok"].map(
                (social) => (
                  <li key={social}>
                    <span className="text-sm text-muted-foreground transition-colors hover:text-primary cursor-pointer">
                      {social}
                    </span>
                  </li>
                )
              )}
            </ul>
          </div>

          <div>
            <h3 className="text-sm font-semibold">Contact</h3>
            <ul className="mt-3 space-y-2">
              <li className="text-sm text-muted-foreground">
                contact@emzrecord.com
              </li>
              <li className="text-sm text-muted-foreground">
                Abidjan, Côte d&apos;Ivoire
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-8 border-t border-border/40 pt-8 text-center">
          <p className="text-xs text-muted-foreground">
            &copy; {new Date().getFullYear()} EMZ RECORD. Tous droits
            réservés.
          </p>
        </div>
      </div>
    </footer>
  );
}
