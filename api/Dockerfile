# api/Dockerfile

FROM node:18
WORKDIR /app

# Önce package.json’ları kopyalayıp bağımlılıkları yükleyelim
COPY package*.json ./
RUN npm install --production

# Geri kalan tüm dosyaları kopyala
COPY . .

# Uygulamayı 8080 portunda başlat
EXPOSE 8080
CMD ["npm", "start"]
