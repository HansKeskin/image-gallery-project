const { Storage } = require('@google-cloud/storage');
const sharp = require('sharp');
const path = require('path');
const os = require('os');
const fs = require('fs');

const storage = new Storage();
const bucketName = process.env.IMAGE_BUCKET;

exports.generateThumbnail = async (event) => {
  const file = event;
  const name = file.name;

  // ZIP dosyalarını ve önceden oluşturulmuş thumb_... dosyalarını atla
  if (name === 'generate-thumbnail.zip' || name.startsWith('thumb_')) {
    console.log(`Skipping processing for ${name}`);
    return;
  }

  const bucket = storage.bucket(bucketName);
  const tempFilePath = path.join(os.tmpdir(), name);
  const thumbName = `thumb_${name}`;
  const thumbPath = path.join(os.tmpdir(), thumbName);

  // Orijinal dosyayı indir
  await bucket.file(name).download({ destination: tempFilePath });

  // Thumbnail oluştur
  await sharp(tempFilePath)
    .resize(200)
    .toFile(thumbPath);

  // Thumbnail’ı yükle
  await bucket.upload(thumbPath, { destination: thumbName });

  // Geçici dosyaları temizle
  fs.unlinkSync(tempFilePath);
  fs.unlinkSync(thumbPath);
};
