const verifiedDownloadUrl =
  "https://github.com/megabyte0x/stickerport/releases/latest/download/StickerPort.dmg";

export function GET() {
  return Response.redirect(verifiedDownloadUrl, 307);
}
