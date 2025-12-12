#!/usr/bin/env bash
set -euo pipefail

# Security Remediation Script
# This script addresses CRITICAL-001 and CRITICAL-002 from the audit report

echo "🔒 Security Remediation - Phase 1"
echo "=================================="
echo ""

# Step 1: Remove exposed .env file (not in git history, safe to delete)
echo "Step 1: Removing exposed .env file..."
if [[ -f ".env" ]]; then
	# Backup for user reference (they'll need to recreate with new keys)
	cp .env .env.EXPOSED_BACKUP_$(date +%Y%m%d_%H%M%S)
	rm .env
	echo "✅ Removed .env (backup saved as .env.EXPOSED_BACKUP_*)"
else
	echo "ℹ️  .env not found (already removed)"
fi

# Step 2: Remove MCP backup files
echo ""
echo "Step 2: Removing MCP backup files with exposed credentials..."
if [[ -d "mcp/backups" ]]; then
	# Backup the directory for reference
	BACKUP_DIR="mcp/backups.EXPOSED_BACKUP_$(date +%Y%m%d_%H%M%S)"
	mv mcp/backups "$BACKUP_DIR"
	echo "✅ Moved mcp/backups to $BACKUP_DIR"

	# Stage the deletion
	git rm -r --cached mcp/backups/ 2>/dev/null || true
	echo "✅ Staged mcp/backups/ for removal from git"
else
	echo "ℹ️  mcp/backups not found (already removed)"
fi

# Step 3: Check if files are in git history
echo ""
echo "Step 3: Checking git history for exposed files..."

MCP_IN_HISTORY=$(git log --all --full-history -- "mcp/backups/" 2>/dev/null | wc -l)

if [[ "$MCP_IN_HISTORY" -gt 0 ]]; then
	echo "⚠️  WARNING: MCP backup files ARE in git history!"
	echo "   Commit: 6decabd0d768eb682139da9b5c8ee31041104ffb"
	echo "   Exposed password: mcp1870171sP#"
	echo ""
	echo "   🚨 REQUIRED ACTIONS:"
	echo "   1. Rotate the MCP admin password immediately"
	echo "   2. Run git history cleanup (requires git-filter-repo or bfg)"
	echo ""
	echo "   To clean git history, run ONE of these commands:"
	echo ""
	echo "   Option A (git-filter-repo - recommended):"
	echo "   git filter-repo --path mcp/backups/ --invert-paths --force"
	echo ""
	echo "   Option B (bfg):"
	echo "   java -jar bfg.jar --delete-folders mcp/backups"
	echo "   git reflog expire --expire=now --all && git gc --prune=now --aggressive"
	echo ""
	echo "   After cleanup, force push to all remotes:"
	echo "   git push origin --force --all"
	echo "   git push origin --force --tags"
else
	echo "✅ MCP backups not in git history"
fi

# Step 4: Verify .gitignore is updated
echo ""
echo "Step 4: Verifying .gitignore..."
if grep -q "mcp/backups/" .gitignore && grep -q "\*\*/*_Settings_\*.json" .gitignore; then
	echo "✅ .gitignore already updated with security patterns"
else
	echo "⚠️  .gitignore needs updating (this should have been done already)"
fi

# Step 5: Create .env template if needed
echo ""
echo "Step 5: Ensuring .env.example exists..."
if [[ -f ".env.example" ]]; then
	echo "✅ .env.example exists"
else
	echo "⚠️  .env.example missing (should exist)"
fi

echo ""
echo "=================================="
echo "📋 NEXT STEPS FOR YOU:"
echo "=================================="
echo ""
echo "1. 🔑 ROTATE ALL EXPOSED CREDENTIALS:"
echo "   - Google Gemini API: https://console.cloud.google.com/apis/credentials"
echo "   - You.com API: https://you.com/dashboard"
echo "   - Smithery API: https://smithery.ai/settings"
echo "   - MCP Admin Password: Generate new secure password"
echo ""
echo "2. 📝 CREATE NEW .env FILE:"
echo "   cp .env.example .env"
echo "   # Edit .env with your NEW rotated keys"
echo "   chmod 600 .env"
echo ""
echo "3. 🧹 CLEAN GIT HISTORY (if you have git-filter-repo installed):"
echo "   git filter-repo --path mcp/backups/ --invert-paths --force"
echo "   git push origin --force --all"
echo ""
echo "4. ✅ COMMIT THESE CHANGES:"
echo "   git add .gitignore"
echo "   git commit -m 'security: Remove exposed credentials and update gitignore'"
echo ""
echo "5. 🔍 RUN SECRET SCANNER:"
echo "   detect-secrets scan > .secrets.baseline"
echo "   detect-secrets audit .secrets.baseline"
echo ""
