FROM node:20-alpine

# Create working directory
WORKDIR /app

# Install dependencies
RUN npm init -y && \
    npm install axios fast-xml-parser js-yaml

# Copy files
COPY sitemap_spider.js .
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Set permissions
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
