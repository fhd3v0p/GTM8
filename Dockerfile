# Multi-stage build for Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Create .env files if they don't exist
RUN touch .env assets/.env

# Build web app
RUN flutter build web --release

# Production stage - Use nginx to serve static files
FROM nginx:alpine

# Copy built web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration and verify it's static port
COPY nginx-railway.conf /etc/nginx/conf.d/default.conf
RUN cat /etc/nginx/conf.d/default.conf | head -3

# Expose port
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]