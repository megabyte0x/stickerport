const latestReleaseApi =
  "https://api.github.com/repos/megabyte0x/stickerport/releases/latest";
const releaseAssetPath = "/megabyte0x/stickerport/releases/download/";

interface ReleaseAsset {
  browser_download_url?: string;
  name?: string;
}

interface LatestRelease {
  assets?: ReleaseAsset[];
}

function isStickerPortDmg(asset: ReleaseAsset) {
  if (!asset.name?.toLowerCase().endsWith(".dmg")) {
    return false;
  }

  try {
    const downloadUrl = new URL(asset.browser_download_url ?? "");
    return (
      downloadUrl.protocol === "https:" &&
      downloadUrl.hostname === "github.com" &&
      downloadUrl.pathname.startsWith(releaseAssetPath)
    );
  } catch {
    return false;
  }
}

export async function GET() {
  const response = await fetch(latestReleaseApi, {
    cache: "no-store",
    headers: {
      Accept: "application/vnd.github+json",
      "User-Agent": "StickerPort-Website",
      "X-GitHub-Api-Version": "2022-11-28",
    },
  });

  if (!response.ok) {
    return new Response("The latest StickerPort download is temporarily unavailable.", {
      status: 502,
    });
  }

  const release = (await response.json()) as LatestRelease;
  const dmg = release.assets?.find(isStickerPortDmg);

  if (!dmg?.browser_download_url) {
    return new Response("The latest StickerPort release does not include a DMG.", {
      status: 502,
    });
  }

  return Response.redirect(dmg.browser_download_url, 307);
}
