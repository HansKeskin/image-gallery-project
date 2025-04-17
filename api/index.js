const express = require('express');
const { Storage } = require('@google-cloud/storage');
const multer = require('multer');

const app = express();
const port = process.env.PORT || 8080;
const bucketName = process.env.IMAGE_BUCKET;

// Storage istemcisi ve multer ayarı
const storage = new Storage();
const bucket = storage.bucket(bucketName);
const upload = multer({ storage: multer.memoryStorage() });

// Kök path’ine bir bilgilendirme ekleyelim
app.get('/', (req, res) => {
  res.send('Image Gallery API. Kullanabileceğiniz endpointler: GET /images, POST /upload');
});

// Resim yükleme endpoint’i
app.post('/upload', upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).send('No file uploaded.');
  const filename = Date.now() + '_' + req.file.originalname;
  const blob = bucket.file(filename);
  const stream = blob.createWriteStream({ resumable: false });
  stream.on('error', err => res.status(500).send(err));
  stream.on('finish', () => res.status(200).send({ name: filename }));
  stream.end(req.file.buffer);
});

// Resim listesini dönen endpoint
app.get('/images', async (_req, res) => {
  const [files] = await bucket.getFiles();
  res.json(files.map(f => f.name));
});

app.listen(port, () => {
  console.log(`API listening on port ${port}`);
});
