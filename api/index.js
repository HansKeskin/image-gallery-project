const express = require('express');
const { Storage } = require('@google-cloud/storage');
const multer = require('multer');

const app = express();
const port = process.env.PORT || 8080;
const bucketName = process.env.IMAGE_BUCKET;

const storage = new Storage();
const bucket = storage.bucket(bucketName);
const upload = multer({ storage: multer.memoryStorage() });

app.post('/upload', upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).send('No file uploaded.');
  const blob = bucket.file(Date.now() + '_' + req.file.originalname);
  const stream = blob.createWriteStream({ resumable: false });
  stream.on('error', err => res.status(500).send(err));
  stream.on('finish', () => res.status(200).send({ name: blob.name }));
  stream.end(req.file.buffer);
});

app.get('/images', async (req, res) => {
  const [files] = await bucket.getFiles();
  res.json(files.map(f => f.name));
});

app.listen(port, () => console.log(`API listening on port ${port}`));
