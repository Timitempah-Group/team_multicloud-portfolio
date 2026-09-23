import matplotlib.pyplot as plt

# AWS total: pending -- Cost Explorer's Project tag filter was only activated
# today and can take up to 24 hours to populate. Re-run the tag-filtered
# query once available and update this value before finalizing.
aws_total_usd = 0.00  # PLACEHOLDER -- replace once tag-filtered query returns real data

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
