# Multi-Cloud Portfolio: AWS + Azure

A ten-task, cross-cloud infrastructure project connecting AWS and Azure with a real, working VPN tunnel; live workloads on both sides; automated global DNS failover between them; unified monitoring; combined cost visibility; a full security and cost governance close-out; and CI/CD pipelines on both clouds.

Every task is built with Terraform, documented with its own README, and backed by real evidence -- command output, timed test results, and screenshots -- rather than description alone.

## Architecture

- **AWS:** VPC (`10.100.0.0/16`), Application Load Balancer + Auto Scaling Group, Route 53
- **Azure:** VNet (`10.200.0.0/16`), Application Gateway + App Service, Traffic Manager
- **Cross-cloud:** a dual-tunnel, route-based IPsec VPN connecting both networks; AWS DMS replicating data from RDS MySQL to Azure SQL Database; a shared DNS failover story spanning both clouds' public entry points

## Tasks

| # | Task | What It Proves |
|---|------|-----------------|
| 1 | [Cross-Cloud Foundations](tasks/01-cross-cloud-foundations) | A real, working VPN tunnel between AWS and Azure, not just two isolated networks |
| 2 | [Cross-Cloud Data Migration](tasks/02-cross-cloud-data-migration) | Live data replication from AWS RDS to Azure SQL via DMS, including CDC |
| 3 | [AWS-Side Workload](tasks/03-aws-workload) | A load-balanced, self-healing, auto-scaling AWS web tier |
| 4 | [Azure-Side Workload](tasks/04-azure-workload) | The same workload pattern on Azure, using a managed-platform (App Service) approach rather than repeating AWS's VM-fleet pattern |
| 5 | [Global DNS Failover](tasks/05-dns-failover) | Automatic, timed failover and failback between AWS and Azure, induced and measured, not just configured |
| 6 | [Unified Monitoring with Grafana](tasks/06-grafana-monitoring) | One dashboard tool querying both clouds' native metrics with no credentials hardcoded |
| 7 | [The Cross-Cloud Dashboard](tasks/07-cross-cloud-dashboard) | Both clouds' health visualised side by side, captured live during an induced failure and recovery |
| 8 | [Cost Visibility Across Both Clouds](tasks/08-cost-visibility) | Combined AWS + Azure spend in a single view, filtered to this project specifically |
| 9 | [Security & Cost Governance Close-Out](tasks/09-governance-close-out) | A verified, zero-orphan teardown of everything built -- nothing left running, nothing forgotten |
| 10 | Cross-Cloud CI/CD | Pipelines (GitHub Actions for AWS, Azure DevOps for Azure) that deploy real infrastructure from nothing, gated by review |

## Repository Structure

Each `tasks/NN-name/` directory contains:
- `terraform/` -- the Infrastructure as Code for that task
- `README.md` -- architecture, design decisions, issues encountered and how they were fixed, and verification evidence
- `screenshots/` (where applicable) -- visual proof of working infrastructure

## A Note on Discipline, Not Just Architecture

Several decisions across this project were driven as much by operational discipline as by architecture:
- Expensive resources (VPN Gateways, Application Gateways, the Grafana workspace) were torn down immediately after their evidence was captured, and rebuilt only when a later task genuinely needed them live again -- rather than left running for convenience.
- Every resource was tagged or grouped from the start specifically so that cost auditing and final teardown could be verified with a single query, not a manual hunt.
- Where something didn't work as expected -- a misnamed Azure role, a missing IAM permission, a stale build-guide reference to a deprecated setting -- the fix and the reasoning behind it are documented in that task's README rather than silently corrected.

## Current Status

Tasks 1-9 complete. Task 10 in progress.
