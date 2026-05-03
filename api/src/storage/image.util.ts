import sharp from 'sharp';

const ALLOWED_INPUT_MIMES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);

// Magic bytes for supported image formats
const MAGIC: Array<{ mime: string; bytes: number[]; offset?: number }> = [
  { mime: 'image/jpeg', bytes: [0xff, 0xd8, 0xff] },
  { mime: 'image/png', bytes: [0x89, 0x50, 0x4e, 0x47] },
  { mime: 'image/webp', bytes: [0x52, 0x49, 0x46, 0x46], offset: 0 }, // "RIFF"
  { mime: 'image/heic', bytes: [0x66, 0x74, 0x79, 0x70], offset: 4 }, // "ftyp"
];

/** Returns the detected MIME type or null if the buffer is not a recognised image. */
export function detectImageMime(buffer: Buffer): string | null {
  for (const { bytes, offset = 0 } of MAGIC) {
    if (bytes.every((b, i) => buffer[offset + i] === b)) {
      // WebP: must also have "WEBP" at offset 8
      if (bytes[0] === 0x52) {
        const webp = [0x57, 0x45, 0x42, 0x50];
        if (!webp.every((b, i) => buffer[8 + i] === b)) continue;
      }
      const match = MAGIC.find(
        (m) => m.bytes === bytes && (m.offset ?? 0) === offset,
      );
      return match?.mime ?? null;
    }
  }
  return null;
}

export function isAllowedImageMime(mime: string | null): mime is string {
  return mime !== null && ALLOWED_INPUT_MIMES.has(mime);
}

/** Resize to ≤1280×1280, auto-orient from EXIF, re-encode as WebP quality 80. */
export async function processVehicleImage(
  buffer: Buffer,
): Promise<{ buffer: Buffer; mimeType: string; ext: string }> {
  const processed = await sharp(buffer)
    .rotate()
    .resize({
      width: 1280,
      height: 1280,
      fit: 'inside',
      withoutEnlargement: true,
    })
    .webp({ quality: 80 })
    .toBuffer();

  return { buffer: processed, mimeType: 'image/webp', ext: 'webp' };
}
