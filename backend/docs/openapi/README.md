# OpenAPI and Swagger Preview

## Run local Swagger UI

From repository root:

```bash
npm run docs:swagger
```

Open browser:

- http://localhost:8080

## Notes

- The preview server serves files from the `docs/` directory.
- Change port with environment variable `SWAGGER_PORT`.
  - PowerShell example: `$env:SWAGGER_PORT='8090'; npm run docs:swagger`

## Available specs

- `/openapi/identity-service.yaml`
- `/openapi/inventory-service.yaml`
- `/openapi/intelligence-service.yaml`
