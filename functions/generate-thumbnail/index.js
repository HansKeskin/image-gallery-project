const { Storage } = require('@google-cloud/storage');
const sharp = require('sharp');
const path = require('path');
const os = require('os');
const fs = require('fs');

const storage = new Storage();
const bucketName = process.env.IMAGE_BUCKET;

exports.generateThumbnail = async (event) => {
  const file = event;
  const bucket = storage.bucket(bucketName);
  const tempFilePath = path.join(os.tmpdir(), file.name);
  const thumbName = `thumb_${file.name}`;
  const thumbPath = path.join(os.tmpdir(), thumbName);

  // İndir
  await bucket.file(file.name).download({ destination: tempFilePath });

  // Thumbnail oluştur
  await sharp(tempFilePath)
    .resize(200)
    .toFile(thumbPath);

  // Yükle
  await bucket.upload(thumbPath, { destination: thumbName });lstat

  // Geçici dosyaları temizle
  fs.unlinkSync(tempFilePath);
  fs.unlinkSync(thumbPath);
};
