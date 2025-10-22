FROM docker.n8n.io/n8nio/n8n:1.115.2

USER root

# Install Tesseract OCR for Alpine Linux
RUN apk update &&  apk add --no-cache perl poppler-utils imagemagick ghostscript graphicsmagick poppler-utils

# Switch back to node user so n8n stores data in /home/node/.n8n (where volume is mounted)
USER node
