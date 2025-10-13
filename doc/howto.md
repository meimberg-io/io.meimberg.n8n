# Update (docker) auf live

```bash
# als root

vim /srv/n8n/Dockerfile # Version anpassen
docker build -t n8n-custom /srv/n8n
systemctl restart n8n.service

```

# Install libs on OS level

```bash
# als root
vim /srv/n8n/Dockerfile
```
In der entsperechenden Zeile die lib hinzufügen, z.B.:
```dockerfile
RUN apk update &&  apk add --no-cache perl mynewlib poppler-utils imagemagick
```

Neu builden und restarten
```bash
docker build -t n8n-custom /srv/n8n
systemctl restart n8n.service
```


# Install node packages (community nodes)

```bash
# als root
vim /srv/n8n/Dockerfile
```
Folgendes hinzufügen (USER und WORKDIR vermutlich schon vohanden)

```dockerfile
USER node
WORKDIR /home/node/.n8n/nodes
RUN npm i n8n-nodes-pdf2image
```

Neu builden und restarten
```bash
docker build -t n8n-custom /srv/n8n
systemctl restart n8n.service
```

