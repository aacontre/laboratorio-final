#!/bin/bash


# Configuración de variables
SONAR_TOKEN="${{ secrets.SONAR_TOKEN }}"
PROJECT_NAME="${{ github.event.repository.name }}"
ORGANIZATION="olimpo"

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
      -d "name=main" \
      -d "project=${PROJECT_NAME}"
  fi
fi