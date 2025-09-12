# CI/CD Improvement Checklist

Actionable items to evolve the pipeline pragmatically. Check off as you implement.

## CI (Pull Requests)

- [ ] Add PR concurrency to cancel superseded runs
  - `concurrency: { group: pr-${{ github.ref }}, cancel-in-progress: true }`
- [ ] Cache Bun to speed installs (`~/.bun` keyed by `bun.lock`)
- [ ] Add Docker image build verification on service changes (no push)
  - Use `docker/build-push-action` with `push: false`, `platform: linux/amd64`
  - Trigger when `packages/{shortening-service,forwarding-service}/**` changes
- [ ] Optionally run tests selectively for changed packages
  - Use `dorny/paths-filter` to decide which test subsets to run
- [ ] Add coverage reporting (`bun test --coverage`) and PR summary
- [ ] Add lint/format jobs once ESLint/Prettier are configured

## CD (Main Deployments)

- [ ] Add deployment concurrency guard to serialize production deploys
  - `concurrency: production-deploy`
- [ ] Frontend env injection at build time
  - Create `packages/frontend/.env.production` with `VITE_API_BASE_URL=https://${DOMAIN}` in the workflow before build
- [ ] S3 Cache-Control headers for SPA
  - Upload assets with `public,max-age=31536000,immutable`
  - Upload `index.html` with `no-cache`
- [ ] CloudFront invalidation after S3 sync
  - Minimal: invalidate `/index.html` and `/`
  - Optional: broader patterns if needed (avoid `/*` routinely)
- [ ] Tag releases and link images
  - Keep `latest` + `${{ github.sha }}`; optionally create GitHub Releases per deploy
- [ ] Consider pinning ECS tasks to image digests for strict rollouts
  - Update task definition to use the `${{ github.sha }}` tag or digest

## Terraform & Infra Automation

- [ ] Migrate Terraform state to remote backend (S3 + DynamoDB lock)
- [ ] Add `terraform plan` job on PRs touching `infra/**`
- [ ] Add `terraform apply` on `main` with manual approval (environment protection)
- [ ] Add drift detection (scheduled `terraform plan -detailed-exitcode`)
- [ ] Add IaC security scan (e.g., tfsec or Checkov) on PRs

## Security & Compliance

- [ ] Image vulnerability scanning (e.g., Trivy) on PRs and/or after image build
- [ ] Generate SBOM for images (Trivy SBOM or Syft) and attach to releases
- [ ] Scope OIDC role with least-privilege policies (ECR push, ECS UpdateService, S3 sync, CloudFront invalidate)
- [ ] Use GitHub Environments for `production` with required reviewers and scoped secrets
- [ ] Enable Dependabot for GitHub Actions and npm/bun packages

## Observability & Reliability

- [ ] Add CloudWatch alarms
  - ECS service health, task crash loops
  - ALB 5xx/target 5xx spikes
- [ ] Add synthetic checks for `/health` through ALB/CloudFront
- [ ] Log retention review (CloudWatch group currently 7 days in Terraform)
- [ ] Optional: structured tracing/log correlation if needed later

## Monorepo Developer Experience

- [ ] Keep CI fast with path filters (already partially in place)
- [ ] Consider adding a task runner (e.g., Turborepo) for affected-graph builds/tests
- [ ] Add pre-commit hooks for formatting/linting (Husky/Lefthook)

## Housekeeping

- [ ] Fix `packages/forwarding-service/package.json` name typo (`forwading-service` → `forwarding-service`)
- [ ] Document required secrets (already in README): `AWS_DEPLOY_ROLE_ARN`, `AWS_REGION`, `AWS_ACCOUNT_ID`, `DOMAIN`
- [ ] Consider multi-arch images if you target ARM Fargate in future (`linux/arm64`)

---

## References

- CI workflow: `.github/workflows/ci.yml`
- Deploy workflow: `.github/workflows/deploy.yml`
- Infra: `infra/` (ECS, ALB, ECR, Redis, S3 + CloudFront)

