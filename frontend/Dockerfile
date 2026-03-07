# Stage 1: Build
FROM ghcr.io/cirruslabs/flutter:stable AS build

USER root
WORKDIR /app

# Cần thiết cho một số tác vụ git của flutter
RUN git config --global --add safe.directory /app

# Chỉ copy pubspec.yaml để tránh xung đột phiên bản từ pubspec.lock (tạo từ máy Windows)
COPY pubspec.yaml ./
RUN flutter pub get

# Sau đó mới copy toàn bộ và build
COPY . .
RUN flutter config --no-analytics
RUN flutter config --enable-web
RUN flutter --verbose build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
