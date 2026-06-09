export interface Artist {
  id: string;
  name: string;
  slug: string;
  image: string;
  bio: string;
  genre: string;
  spotify?: string;
  appleMusic?: string;
  boomplay?: string;
  audiomack?: string;
}

export interface NewsItem {
  id: string;
  title: string;
  date: string;
  category: string;
  excerpt: string;
  image?: string;
}

export interface ContactMessage {
  id: string;
  name: string;
  email: string;
  phone?: string;
  subject: string;
  message: string;
  type: "studio" | "prestation" | "demo" | "autre";
  status: "unread" | "read" | "replied";
  createdAt: string;
}

export interface DemoSubmission {
  id: string;
  artistName: string;
  email: string;
  link: string;
  description: string;
  genre: string;
  status: "pending" | "reviewing" | "accepted" | "rejected";
  createdAt: string;
}

export interface Project {
  id: string;
  title: string;
  artist: string;
  type: "single" | "album" | "clip";
  cover: string;
  embedUrl?: string;
  releaseDate: string;
  description: string;
}
