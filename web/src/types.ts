export type Build = {
  id: string;
  name: string;
  tree: string;
  tagline: string;
  race: string;
  avoid: string;
  core: string[];
  talents: string[];
  cards: string[];
  jewelry: string[];
  armory: string;
  tip: string;
};

export type ClassEntry = {
  class: string;
  label: string;
  default: string;
  builds: Record<string, Build>;
};

export type BuildsData = {
  classOrder: string[];
  builds: Record<string, ClassEntry>;
};

export type PageId = "Overview" | "Talents" | "Cards" | "Jewelry";
