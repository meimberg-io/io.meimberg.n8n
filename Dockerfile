FROM docker.n8n.io/n8nio/n8n:1.115.2

USER root

# Install Tesseract OCR for Alpine Linux
RUN apk update &&  apk add --no-cache perl poppler-utils imagemagick ghostscript graphicsmagick poppler-utils

#USER node
#WORKDIR /home/node/.n8n/nodes
#RUN npm uninstall n8n-nodes-pdf2image
