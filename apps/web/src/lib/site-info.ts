const DEFAULT_SITE_URL = "https://github.com/TheCrypDough/Grabber";

// ---------- Basic Site Config ----------
export const siteConfig = {
  name: "Grabber",
  description:
    "End copy paste time waste for AI conversations across web, CLI, IDE, and agent workflows.",
  url: process.env.NEXT_PUBLIC_SITE_URL ?? DEFAULT_SITE_URL,
  locale: "en_US",
};

// ---------- GitHub Config ----------
export const githubConfig = {
  username: "TheCrypDough",
  repo: "Grabber",
  get url() {
    return `https://github.com/${this.username}/${this.repo}`;
  },
  get docsBase() {
    return `${this.url}/tree/main/apps/web`;
  },
  get issuesUrl() {
    return `${this.url}/issues/new?labels=feedback,documentation&template=feedback.md`;
  },
};

// ---------- Author Config ----------
export const authorConfig = {
  name: "TheCrypDough",
  website: githubConfig.url,
  email: "",
  github: `https://github.com/${githubConfig.username}`,
};

// ---------- Social Links Config ----------
// Set href to empty string "" to hide a social link
export const socialLinksConfig = {
  github: {
    label: "GitHub",
    href: `https://github.com/${githubConfig.username}`,
  },
  bilibili: {
    label: "Bilibili",
    href: "",
  },
  douyin: {
    label: "Douyin",
    href: "",
    handle: "",
  },
  twitter: {
    label: "X (Twitter)",
    href: "",
  },
};

// ---------- Footer Config ----------
export const footerConfig = {
  links: [
    {
      label: "GitHub",
      href: authorConfig.github,
    },
    {
      label: "About Author",
      href: authorConfig.github,
    },
    {
      label: "Privacy",
      href: "/en/docs/privacy",
    },
    {
      label: "Terms",
      href: "/en/docs/terms",
    },
  ],
  copyright: {
    holder: siteConfig.name,
    license: "MIT",
  },
};

// ---------- Banner Config ----------
export const bannerConfig = {
  storageKey: `${siteConfig.name.toLowerCase().replace(/\s+/g, "-")}-banner`,
};
