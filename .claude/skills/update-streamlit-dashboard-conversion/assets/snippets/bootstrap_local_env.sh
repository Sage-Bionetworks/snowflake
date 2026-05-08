APP_DIR="<APP_DIR>"
ENV_NAME="$(basename "${APP_DIR}")"

if command -v mamba >/dev/null 2>&1; then MGR=mamba; else MGR=conda; fi

if $MGR env list | grep -q "^${ENV_NAME} "; then
  $MGR env update -y -n "${ENV_NAME}" -f "${APP_DIR}/environment.yml" --prune
else
  $MGR env create -y -n "${ENV_NAME}" -f "${APP_DIR}/environment.yml"
fi
