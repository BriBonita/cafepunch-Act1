#!/bin/bash

# deploy.sh - Despliega contenido estático a S3 usando AWS CLI + Git
# Uso:
#   ./deploy.sh <bucket-name> <region>
# Ejemplo: ./deploy.sh cafepunch-act3-test us-east-1

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ─────────────────────────────────────────────────────────
# VALIDACIONES INICIALES
# ─────────────────────────────────────────────────────────

echo -e "${YELLOW}=== DESPLIEGUE AUTOMATIZADO A AWS S3 ===${NC}"
echo ""

# 1. Verificar argumentos
if [[ $# -lt 2 ]]; then
  echo -e "${RED}❌ Error: faltan argumentos${NC}"
  echo "Uso: $0 <bucket-name> <region>"
  echo "Ejemplo: $0 cafepunch-act3-test us-east-1"
  exit 1
fi

BUCKET="$1"
REGION="$2"

# 2. Verificar que Git esté instalado
echo -e "${YELLOW}[1/9] Verificando Git...${NC}"
if ! command -v git &> /dev/null; then
  echo -e "${RED}❌ Git no está instalado${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Git encontrado: $(git --version)${NC}"

# 3. Verificar que AWS CLI esté instalado
echo -e "${YELLOW}[2/9] Verificando AWS CLI...${NC}"
if ! command -v aws &> /dev/null; then
  echo -e "${RED}❌ AWS CLI no está instalado${NC}"
  exit 1
fi
echo -e "${GREEN}✅ AWS CLI encontrado: $(aws --version)${NC}"

# 4. Validar credenciales de AWS
echo -e "${YELLOW}[3/9] Validando credenciales de AWS...${NC}"
if ! AWS_INFO=$(aws sts get-caller-identity --output json 2>/dev/null); then
  echo -e "${RED}❌ No hay credenciales de AWS configuradas${NC}"
  echo "Ejecuta: aws configure"
  exit 1
fi
echo -e "${GREEN}✅ Credenciales válidas:${NC}"
echo "$AWS_INFO" | grep -E "UserId|Account|Arn" | sed 's/^/   /'

# 5. Obtener rama y commit actual
echo -e "${YELLOW}[4/9] Obteniendo información de Git...${NC}"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT=$(git rev-parse --short HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B)
echo -e "${GREEN}✅ Rama: ${CURRENT_BRANCH}${NC}"
echo -e "${GREEN}   Commit: ${CURRENT_COMMIT}${NC}"
echo -e "${GREEN}   Mensaje: ${COMMIT_MSG}${NC}"

# 6. Sincronizar con repositorio remoto
echo -e "${YELLOW}[5/9] Sincronizando con repositorio remoto...${NC}"
if git remote -v | grep -q "origin"; then
  git fetch origin 2>/dev/null || true
  git pull origin "$CURRENT_BRANCH" 2>/dev/null || true
  echo -e "${GREEN}✅ Sincronización completada${NC}"
else
  echo -e "${YELLOW}⚠️  No hay remoto configurado (repositorio local)${NC}"
fi

# 7. Crear bucket si no existe
echo -e "${YELLOW}[6/9] Verificando bucket S3...${NC}"
if aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" 2>/dev/null; then
  echo -e "${GREEN}✅ Bucket existe: $BUCKET${NC}"
else
  echo -e "${YELLOW}   Creando bucket: $BUCKET${NC}"
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint=$REGION
  fi
  echo -e "${GREEN}✅ Bucket creado${NC}"
fi

# 8. Configurar acceso público y política de lectura (SIN ACLs)
echo -e "${YELLOW}[7/9] Configurando permisos y política de lectura...${NC}"

# Desactivar bloqueo de acceso público para permitir política pública
aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false" 2>/dev/null || true

# Aplicar política de lectura pública (sin dependencia de ACLs)
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
echo -e "${GREEN}✅ Permisos configurados (política de bucket pública)${NC}"

# 9. Habilitar hosting estático
echo -e "${YELLOW}[8/9] Habilitando hosting estático...${NC}"
aws s3api put-bucket-website --bucket "$BUCKET" --website-configuration \
  "IndexDocument={Suffix=index.html},ErrorDocument={Key=index.html}"
echo -e "${GREEN}✅ Hosting estático habilitado${NC}"

# 10. Sincronizar contenido (subir y eliminar obsoletos)
echo -e "${YELLOW}[9/9] Subiendo contenido a S3...${NC}"
aws s3 sync . "s3://$BUCKET/" \
  --delete \
  --exclude 'deploy.sh' \
  --exclude 'README.md' \
  --exclude '.git/*' \
  --exclude '.gitignore' \
  --exclude '*.md'

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ DESPLIEGUE COMPLETADO EXITOSAMENTE${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "📍 Rama desplegada: ${GREEN}${CURRENT_BRANCH}${NC}"
echo -e "📍 Commit: ${GREEN}${CURRENT_COMMIT}${NC}"
echo -e "📍 Bucket: ${GREEN}${BUCKET}${NC}"
echo -e "📍 Región: ${GREEN}${REGION}${NC}"
echo ""
echo -e "🌐 ${YELLOW}URL del sitio:${NC}"
echo -e "   ${GREEN}http://${BUCKET}.s3-website-${REGION}.amazonaws.com${NC}"
echo ""
echo -e "📋 ${YELLOW}Archivos en bucket:${NC}"
aws s3 ls "s3://$BUCKET/" --recursive | awk '{print "   " $0}'
echo ""
