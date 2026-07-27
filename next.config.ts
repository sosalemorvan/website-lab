import type { NextConfig } from "next";

const isGithubPages = process.env.GITHUB_PAGES === "true";

const nextConfig: NextConfig = {
  ...(isGithubPages && {
    output: "export",
    basePath: "/website-lab",
    assetPrefix: "/website-lab/",
  }),
  ...(!isGithubPages && { output: "standalone" }),
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
