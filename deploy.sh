#!/bin/bash

# deploy.sh - Despliega contenido estático a S3 usando AWS CLI
# Uso:
#   ./deploy.sh <bucket-name> <region> [--no-invalidate]

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Uso: $0 <bucket-name> <region> [--no-invalidate]"
  echo "Ejemplo: $0 mi-bucket-unico-123 us-east-1"
  exit 1
fi

BUCKET="$1"
REGION="$2"
NO_INVALIDATE=false
if [[ ${3:-} == "--no-invalidate" ]]; then
  NO_INVALIDATE=true
fi

echo "[1/6] Verificando configuración de AWS..."
aws sts get-caller-identity --output json

echo "[2/6] Creando bucket (si no existe)..."
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Bucket existe: $BUCKET"
else
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" --create-bucket-configuration LocationConstraint=$REGION
  echo "Bucket creado: $BUCKET"
fi

echo "[3/6] Aplicando políticas públicas de lectura (sitio estático)..."
cat > /tmp/s3-policy-$$.json <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"PublicReadGetObject",
      "Effect":"Allow",
      "Principal":"*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::$BUCKET/*"]
    }
  ]
}
EOF
aws s3api put-bucket-policy --bucket "$BUCKET" --policy file:///tmp/s3-policy-$$.json
rm -f /tmp/s3-policy-$$.json

echo "[4/6] Habilitando hosting estático..."
aws s3 website s3://$BUCKET/ --index-document index.html --error-document index.html

echo "[5/6] Subiendo contenido..."
aws s3 sync . s3://$BUCKET/ --acl public-read --delete --exclude 'deploy.sh' --exclude 'README.md' --exclude '.git/*'

echo "[6/6] Listado de archivos en bucket..."
aws s3 ls s3://$BUCKET/ --recursive

echo "✅ Despliegue completado. URL: http://$BUCKET.s3-website-$REGION.amazonaws.com"

if [[ "$NO_INVALIDATE" == false ]]; then
  echo "(No hay invalidación de CloudFront en este script, se puede añadir si usas CDN.)"
fi
