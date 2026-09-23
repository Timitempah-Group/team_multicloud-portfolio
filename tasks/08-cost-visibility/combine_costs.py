import matplotlib.pyplot as plt

# AWS total: sourced from the full account-wide Cost Explorer breakdown
# (Sept 1-24), not the Project tag filter -- AWS cost allocation tags are
# not retroactive, so a tag activated only hours before this data was
# needed cannot attribute historical usage. Every non-zero service in the
# account-wide breakdown matches this project's known resource types
# (EC2, ELB, RDS, DMS, VPC, Route 53, Secrets Manager, plus the small
# Terraform state backend and Cost Explorer's own API charges), giving
# high confidence this total genuinely reflects this project. Pre-tax.
aws_total_usd = 40.09

# Azure total: confirmed from Cost Management, scoped to rg-multicloud-portfolio,
# September 2026 to date. Converted from GBP to USD at approximately 1.27 (Sept 2026 rate).
azure_total_gbp = 14.93
gbp_to_usd_rate = 1.27
azure_total_usd = azure_total_gbp * gbp_to_usd_rate

fig, ax = plt.subplots(figsize=(6, 4))
ax.bar(["AWS", "Azure"], [aws_total_usd, azure_total_usd], color=["#FF9900", "#0078D4"])
ax.set_ylabel("Spend (USD)")
ax.set_title("multicloud-portfolio - Combined Cloud Spend (September 2026)")
for i, v in enumerate([aws_total_usd, azure_total_usd]):
    ax.text(i, v, f"${v:.2f}", ha="center", va="bottom")
plt.tight_layout()
plt.savefig("reports/cost-summary.png", dpi=150)
print(f"AWS: ${aws_total_usd:.2f}  Azure: ${azure_total_usd:.2f}  Combined: ${aws_total_usd + azure_total_usd:.2f}")
