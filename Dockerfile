```dockerfile
# Stage 1: Build the React application
FROM node:lts-alpine as builder

WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock/pnpm-lock.yaml)
# to leverage Docker cache for dependencies
COPY package.json package-lock.json ./

# Install dependencies
# 'npm ci' is preferred for CI/CD builds for reproducibility
RUN npm ci --prefer-offline --no-audit

# Copy the rest of the application code
COPY . .

# Build the React application
# This typically outputs static files into the 'dist' directory
RUN npm run build

# Stage 2: Serve the application with Nginx
FROM nginx:stable-alpine

# Remove default Nginx configuration file
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom Nginx configuration for a Single Page Application (SPA)
# This ensures that client-side routing works by falling back to index.html
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
  listen 80;
  location / {
    root /usr/share/nginx/html;
    index index.html index.htm;
    try_files \$uri \$uri/ /index.html;
  }
}
EOF

# Copy the built React application from the builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port 80 to the host
EXPOSE 80

# Command to run Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
```