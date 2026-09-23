# Task 9: Security & Cost Governance Close-Out

A full tagging audit, an ordered teardown of every remaining resource across both clouds, and verification that the account is genuinely left in a zero-orphan state.

## Why This Task Exists

A project that gets "finished" but never properly decommissioned is a common, real source of cloud waste. This task exists to prove the opposite discipline: that everything built across this portfolio can be identified, accounted for, and completely removed, with nothing left running and nothing forgotten.

## Approach

**Before/after tagging audit.** Every AWS resource created across this portfolio was tagged `Project=multicloud-portfolio` from the start; every Azure resource lived inside the single `rg-multicloud-portfolio` resource group. This meant a full account inventory was always a single query away in either cloud, rather than a manual hunt.

**Teardown order.** Resources were destroyed in reverse dependency order, through each task's own Terraform state, rather than deleted by hand outside of Terraform:
1. Task 5 (Route 53 zone, health check, records; Azure Traffic Manager profile and endpoints)
2. Task 3 (AWS ALB, target group, launch template, Auto Scaling Group, security groups, S3 VPC endpoint)
3. Task 2's remaining resources (Azure SQL Server/Database, the DMS VPC IAM role, the Secrets Manager secret -- kept alive as the portfolio's "permanent migrated data" artifact until this final close-out)
4. Task 1's foundational networking (the AWS VPC and all its subnets/route tables/gateways; the Azure VNet, its subnets, and the resource group container itself)

Tasks 4 and 6's resources (Azure App Gateway/App Service, and the Grafana workspace) had already been torn down earlier in the portfolio, immediately after their respective evidence was captured, consistent with this project's running discipline of not leaving expensive resources live once their job is done.

## Issues Encountered

**Cross-task Terraform outputs broke as dependent resources were destroyed.** Task 5's configuration referenced Task 4's Terraform outputs; Task 2's configuration referenced Task 1's outputs. Once the upstream resources were destroyed, their outputs disappeared from state entirely, causing `Unsupported attribute` errors when the downstream task's destroy tried to build its plan -- even though the actual values were no longer needed for a destroy operation. Fixed each time by temporarily substituting harmless placeholder values (or, where the real value was already known, the real value directly) in place of the broken remote-state reference, purely to let Terraform's destroy plan resolve.

**Azure refused to delete the resource group while the SQL Server/Database still existed inside it**, even though those resources were never created by the same Terraform state doing the deleting. This is a deliberate Azure safety check (`prevent_deletion_if_contains_resources`), not a bug. Rather than disabling the safety check, the SQL Server and Database were destroyed properly through Task 2's own Terraform state first, after which the resource group genuinely was empty and could be removed cleanly.

**Secrets Manager's default 30-day recovery window would have left a "deleted but not gone" secret lingering for weeks.** Both secrets created across this portfolio (the VPN PSK, and Task 2's DB admin password) were explicitly force-purged with `--force-delete-without-recovery` rather than left in their default pending-deletion state, for a genuinely complete close-out rather than a merely-scheduled one.

## Verification

**Before:** 17 AWS-tagged resource ARNs, 5 Azure resources in the resource group.

**After:** the AWS tagging query returns an empty result; `az group exists --name rg-multicloud-portfolio` returns `false`. See `evidence/before-teardown.txt` and `evidence/after-teardown.txt` for the full, plain-text audit output.

## What's Deliberately Not Torn Down

Nothing. This is a genuine zero-orphan close-out -- every resource created across all nine prior tasks has been accounted for and removed, including the Azure SQL Database that had been kept alive since Task 2 as the portfolio's permanent evidence of the completed migration.

## Note on Task 10

Task 10 (Cross-Cloud CI/CD) will redeploy real infrastructure from this now-empty state, driven entirely by its own pipeline (GitHub Actions for AWS, Azure DevOps for Azure) rather than manual `terraform apply`. This is a deliberate design choice: a pipeline that can stand up infrastructure from nothing is stronger evidence of genuine CI/CD capability than one that only modifies infrastructure already running.
