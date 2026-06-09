export function AnimatedGradient() {
  return (
    <div className="pointer-events-none fixed inset-0 z-0 overflow-hidden">
      <div className="absolute -top-1/2 -left-1/2 h-[1000px] w-[1000px] animate-spin-slow rounded-full bg-gradient-to-r from-primary/5 via-primary/10 to-transparent opacity-30 blur-3xl" />
      <div
        className="absolute -bottom-1/2 -right-1/2 h-[800px] w-[800px] animate-spin-slow rounded-full bg-gradient-to-l from-primary/8 via-primary/5 to-transparent opacity-20 blur-3xl"
        style={{ animationDirection: "reverse", animationDuration: "25s" }}
      />
    </div>
  );
}
