# data-sync Helm Chart

Helm chart for deploying the Python FastAPI `data-sync` service with Redis caching and Prometheus monitoring.

## Verification

Lint chart templates and syntax:
```bash
helm lint helm/charts/data-sync/
helm lint helm/charts/data-sync/ -f helm/charts/data-sync/values.staging.yaml
helm lint helm/charts/data-sync/ -f helm/charts/data-sync/values.production.yaml