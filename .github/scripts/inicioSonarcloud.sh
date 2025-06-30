#!/bin/bash

#validando parametros
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Error: Faltan parámetros"
  echo "Uso: $0 <SONAR_TOKEN> <PROJECT_NAME> <ORGANIZATION>"
  exit 1
fi
# Configuración de variables (las variables de GitHub Actions se pasan como argumentos)
SONAR_TOKEN="$1"
PROJECT_NAME="$2"
ORGANIZATION="$3"

# Función para verificar si el proyecto existe
check_project_exists() {
  curl -s -u "${SONAR_TOKEN}:" "https://sonarcloud.io/api/components/show?component=${PROJECT_NAME}" | grep -q '"errors"'
  return $?
}

# Intento de creación del proyecto
if check_project_exists; then
  echo "El proyecto ${PROJECT_NAME} ya existe en SonarCloud"
  echo "proyectoExiste=1" >> $GITHUB_OUTPUT
else
  echo "Creando proyecto ${PROJECT_NAME} en SonarCloud..."
  curl_response=$(curl -f -X POST -u "${SONAR_TOKEN}:" \
    "https://sonarcloud.io/api/projects/create" \
    -d "name=${PROJECT_NAME}" \
    -d "project=${PROJECT_NAME}" \
    -d "organization=${ORGANIZATION}" \
    -d "visibility=public" 2>&1)
  
  if [ $? -ne 0 ]; then
    echo "Error al crear proyecto: ${curl_response}"
    exit 1
  else
    echo "Proyecto ${PROJECT_NAME} creado exitosamente en SonarCloud"
    echo "proyectoExiste=0" >> $GITHUB_OUTPUT
    
    # Configurar rama main como rama por defecto
    echo "Configurando rama main como rama por defecto..."
    curl -X POST -u "${SONAR_TOKEN}:" \
      "https://sonarcloud.io/api/project_branches/rename" \
      -d "name=feat-movie" \
      -d "project=${PROJECT_NAME}"
  fi
fi