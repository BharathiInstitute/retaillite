/**
 * Tulasi Stores — Icon Generator v2
 * Source: "assets/images/new icon.png" (green store, white bg, 257x238)
 * 
 * Steps:
 *  1. Remove white background -> transparent
 *  2. Trim transparent edges
 *  3. Make square with padding
 *  4. Upscale to 1024x1024
 *  5. Generate all platform icons
 */

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const SOURCE = 'assets/images/new icon.png';

async function removeWhiteAndMakeSquare(inputPath) {
  console.log('Loading: ' + inputPath);
  
  const srcBuffer = fs.readFileSync(inputPath);
  const image = sharp(srcBuffer);
  const meta = await image.metadata();
  console.log('   Original: ' + meta.width + 'x' + meta.height + ', alpha: ' + meta.hasAlpha);
  
  // Get raw RGBA pixels
  const result = await sharp(srcBuffer)
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  
  const data = result.data;
  const info = result.info;
  
  // Remove white/near-white background -> transparent
  const threshold = 230;
  let removedCount = 0;
  
  for (let i = 0; i < data.length; i += 4) {
    const r = data[i], g = data[i + 1], b = data[i + 2];
    if (r > threshold && g > threshold && b > threshold) {
      data[i + 3] = 0;
      removedCount++;
    }
  }
  
  // Clean up anti-aliasing edges
  for (let i = 0; i < data.length; i += 4) {
    const r = data[i], g = data[i + 1], b = data[i + 2], a = data[i + 3];
    if (a > 0 && r > 200 && g > 200 && b > 200) {
      const lightness = (r + g + b) / 3;
      const newAlpha = Math.round(a * (1 - (lightness - 200) / 55));
      data[i + 3] = Math.max(0, Math.min(255, newAlpha));
    }
  }
  
  const totalPixels = info.width * info.height;
  console.log('   Removed ' + removedCount + '/' + totalPixels + ' white pixels (' + (removedCount/totalPixels*100).toFixed(1) + '%)');
  
  // Create trimmed transparent image
  const transparentImage = sharp(data, {
    raw: { width: info.width, height: info.height, channels: 4 }
  });
  
  // Trim transparent edges
  const trimmed = await transparentImage
    .trim()
    .toBuffer({ resolveWithObject: true });
  
  console.log('   After trim: ' + trimmed.info.width + 'x' + trimmed.info.height);
  
  // Make square by padding shorter dimension (add 12% breathing room)
  const maxDim = Math.max(trimmed.info.width, trimmed.info.height);
  const squareSize = Math.round(maxDim * 1.12);
  
  const squareBuffer = await sharp(trimmed.data, {
    raw: { width: trimmed.info.width, height: trimmed.info.height, channels: 4 }
  })
    .resize(squareSize, squareSize, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 }
    })
    .png()
    .toBuffer();
  
  console.log('   Square padded: ' + squareSize + 'x' + squareSize);
  
  // Upscale to 1024x1024
  const masterBuffer = await sharp(squareBuffer)
    .resize(1024, 1024, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
      kernel: 'lanczos3'
    })
    .png()
    .toBuffer();
  
  console.log('   Master: 1024x1024');
  return masterBuffer;
}

async function createMaskableIcon(transparentBuffer, size) {
  const padding = Math.round(size * 0.17);
  const innerSize = size - (padding * 2);

  const resizedLogo = await sharp(transparentBuffer)
    .resize(innerSize, innerSize, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();

  return sharp({
    create: { width: size, height: size, channels: 4, background: { r: 255, g: 255, b: 255, alpha: 255 } }
  })
    .composite([{ input: resizedLogo, gravity: 'centre' }])
    .png()
    .toBuffer();
}

async function createAdaptiveForeground(transparentBuffer) {
  const safeZone = Math.round(1024 * 0.66);
  
  const resizedLogo = await sharp(transparentBuffer)
    .resize(safeZone, safeZone, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();

  return sharp({
    create: { width: 1024, height: 1024, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } }
  })
    .composite([{ input: resizedLogo, gravity: 'centre' }])
    .png()
    .toBuffer();
}

function createIco(pngBuffers, sizes) {
  const numImages = pngBuffers.length;
  let dataOffset = 6 + (16 * numImages);
  const parts = [];
  
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(numImages, 4);
  parts.push(header);
  
  for (let i = 0; i < numImages; i++) {
    const entry = Buffer.alloc(16);
    const s = sizes[i];
    entry.writeUInt8(s < 256 ? s : 0, 0);
    entry.writeUInt8(s < 256 ? s : 0, 1);
    entry.writeUInt8(0, 2);
    entry.writeUInt8(0, 3);
    entry.writeUInt16LE(1, 4);
    entry.writeUInt16LE(32, 6);
    entry.writeUInt32LE(pngBuffers[i].length, 8);
    entry.writeUInt32LE(dataOffset, 12);
    dataOffset += pngBuffers[i].length;
    parts.push(entry);
  }
  
  for (const buf of pngBuffers) parts.push(buf);
  return Buffer.concat(parts);
}

async function main() {
  console.log('Tulasi Stores Icon Generator v2');
  console.log('===================================');
  console.log('');
  
  // Step 1: Process source icon
  console.log('Step 1: Processing source icon...');
  const masterBuffer = await removeWhiteAndMakeSquare(SOURCE);
  
  // Step 2: Generate all variants
  console.log('');
  console.log('Step 2: Generating all icon variants...');
  console.log('');
  
  // Master assets
  await sharp(masterBuffer).toFile('assets/images/app_icon.png');
  console.log('  OK assets/images/app_icon.png (1024x1024 transparent)');
  
  const fgBuffer = await createAdaptiveForeground(masterBuffer);
  await sharp(fgBuffer).toFile('assets/images/app_icon_foreground.png');
  console.log('  OK assets/images/app_icon_foreground.png (1024x1024 adaptive fg)');
  
  await sharp(masterBuffer)
    .resize(512, 512, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toFile('assets/images/splash_logo.png');
  console.log('  OK assets/images/splash_logo.png (512x512 transparent)');
  
  // Web icons
  await sharp(masterBuffer).resize(48, 48).png().toFile('web/favicon.png');
  console.log('  OK web/favicon.png (48x48)');
  
  await sharp(masterBuffer).resize(192, 192).png().toFile('web/icons/Icon-192.png');
  console.log('  OK web/icons/Icon-192.png (192x192)');
  
  await sharp(masterBuffer).resize(512, 512).png().toFile('web/icons/Icon-512.png');
  console.log('  OK web/icons/Icon-512.png (512x512)');
  
  const maskable192 = await createMaskableIcon(masterBuffer, 192);
  fs.writeFileSync('web/icons/Icon-maskable-192.png', maskable192);
  console.log('  OK web/icons/Icon-maskable-192.png (192x192 maskable)');
  
  const maskable512 = await createMaskableIcon(masterBuffer, 512);
  fs.writeFileSync('web/icons/Icon-maskable-512.png', maskable512);
  console.log('  OK web/icons/Icon-maskable-512.png (512x512 maskable)');
  
  // Website
  await sharp(masterBuffer).resize(512, 512).png().toFile('website/assets/images/app_icon.png');
  console.log('  OK website/assets/images/app_icon.png (512x512)');
  
  await sharp(masterBuffer)
    .resize(512, 512, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toFile('website/assets/images/splash_logo.png');
  console.log('  OK website/assets/images/splash_logo.png (512x512)');
  
  // Windows ICO
  console.log('');
  console.log('  Generating Windows .ico...');
  const icoSizes = [16, 32, 48, 256];
  const icoPngs = await Promise.all(
    icoSizes.map(function(sz) { return sharp(masterBuffer).resize(sz, sz).png().toBuffer(); })
  );
  const icoBuffer = createIco(icoPngs, icoSizes);
  fs.writeFileSync('windows/runner/resources/app_icon.ico', icoBuffer);
  console.log('  OK windows/runner/resources/app_icon.ico (16,32,48,256)');
  
  // Verify
  console.log('');
  console.log('Step 3: Verification...');
  console.log('');
  const verify = [
    'assets/images/app_icon.png',
    'assets/images/app_icon_foreground.png',
    'assets/images/splash_logo.png',
    'web/favicon.png',
    'web/icons/Icon-192.png',
    'web/icons/Icon-512.png',
    'web/icons/Icon-maskable-192.png',
    'web/icons/Icon-maskable-512.png',
    'website/assets/images/app_icon.png',
    'windows/runner/resources/app_icon.ico'
  ];
  
  for (const f of verify) {
    try {
      if (f.endsWith('.ico')) {
        const stat = fs.statSync(f);
        console.log('  OK ' + f + ' ' + (stat.size/1024).toFixed(1) + 'KB');
      } else {
        const m = await sharp(f).metadata();
        console.log('  OK ' + f + ' ' + m.width + 'x' + m.height + ' ' + (m.hasAlpha ? 'transparent' : 'opaque'));
      }
    } catch(e) {
      console.log('  FAIL ' + f + ' - ' + e.message);
    }
  }
  
  console.log('');
  console.log('===================================');
  console.log('All icons generated from green store logo!');
}

main().catch(function(err) {
  console.error('Error: ' + err.message);
  console.error(err.stack);
  process.exit(1);
});
