# How to Run and Check PigOS Code

This guide will help you verify that the HyDE → PigOS migration was successful and test the codebase.

## Quick Validation Checks

### 1. Check for Remaining HyDE References

First, verify that all references have been renamed:

```bash
# Search for any remaining 'hyde' references (case-insensitive)
grep -r "hyde" . --exclude-dir=.git --exclude-dir=Source/arcs --exclude-dir=Assets | grep -v "HyDE-Project" | grep -v "hyde-themes" | grep -v "hyde-gallery" | head -20

# Search for 'HyDE' (case-sensitive)
grep -r "HyDE" . --exclude-dir=.git --exclude-dir=Source/arcs --exclude-dir=Assets | grep -v "HyDE-Project" | head -20

# Check for old path references
grep -r "\.config/hyde" . --exclude-dir=.git
grep -r "\.cache/hyde" . --exclude-dir=.git
grep -r "\.local/lib/hyde" . --exclude-dir=.git
```

**Expected:** Should only find external references (HyDE-Project, hyde-themes, etc.) or be empty.

### 2. Verify Script Syntax

Check that all shell scripts have valid syntax:

```bash
cd Scripts

# Check main install script
bash -n install.sh

# Check other critical scripts
bash -n global_fn.sh
bash -n version.sh
bash -n uninstall.sh
bash -n themepatcher.sh
bash -n restore_thm.sh

# Check PigOSVM script
bash -n pigosvm/pigosvm.sh
```

**Expected:** No syntax errors should be reported.

### 3. Check Variable Usage

Verify that variables are properly renamed:

```bash
# Should find PIGOS_LOG (not HYDE_LOG)
grep -r "PIGOS_LOG" Scripts/

# Should find PIGOS_ variables in version.sh
grep "PIGOS_" Scripts/version.sh

# Should NOT find HYDE_LOG (except in comments or old code)
grep -r "HYDE_LOG" Scripts/ | grep -v "#" | grep -v "PIGOS"
```

## Testing Installation Script (Dry Run)

### Safe Testing Without Installing

The install script has a `-t` (test/dry-run) flag that shows what would happen without actually executing:

```bash
cd Scripts

# Dry run of full installation
./install.sh -irst

# Dry run of restore only
./install.sh -rt

# Dry run with no nvidia detection
./install.sh -irstn
```

**What this does:**
- Shows all commands that would be executed
- Validates package lists
- Checks for dependencies
- **Does NOT** install anything or modify your system

### Check Script Options

```bash
cd Scripts
./install.sh --help
# or just
./install.sh -h
```

## Testing in a Virtual Machine (Recommended)

### Using PigOSVM

The safest way to test is using PigOSVM in a VM:

```bash
cd Scripts/pigosvm

# 1. Check if dependencies are installed
./pigosvm.sh --check-deps

# 2. Install dependencies (Arch Linux only)
./pigosvm.sh --install-deps

# 3. Run PigOS in a VM (non-persistent - changes are discarded)
./pigosvm.sh

# 4. Run in persistent mode (changes are saved)
./pigosvm.sh --persist

# 5. List available snapshots
./pigosvm.sh --list
```

**VM Details:**
- Login: `arch` / `arch`
- Root password: `pigosvm` / `pigosvm`
- SSH: `ssh arch@localhost -p 2222`

### Using Nix Flakes (NixOS)

If you're on NixOS or have Nix installed:

```bash
# Run PigOSVM using Nix
nix run .#pigosvm

# Or build and run
nix build .#pigosvm
./result/bin/pigosvm
```

## Manual Code Review Checklist

### Scripts to Review

1. **Scripts/install.sh**
   - [ ] All `HYDE_LOG` → `PIGOS_LOG`
   - [ ] All `hyde` paths → `pigos` paths
   - [ ] Script runs without errors in dry-run mode

2. **Scripts/global_fn.sh**
   - [ ] `cacheDir` uses `pigos` not `hyde`
   - [ ] `pacmanCmd` path updated
   - [ ] `PIGOS_LOG` variable used

3. **Scripts/version.sh**
   - [ ] All `HYDE_*` variables → `PIGOS_*`
   - [ ] Output shows "PigOS" not "HyDE"

4. **Scripts/pigosvm/pigosvm.sh**
   - [ ] Repository URL updated (or placeholder noted)
   - [ ] All references to `HyDE` → `PigOS`
   - [ ] All `hydevm` → `pigosvm`

5. **flake.nix**
   - [ ] Description updated
   - [ ] References `pigosvm` not `hydevm`

### Documentation to Review

1. **README.md**
   - [ ] Attribution section present
   - [ ] All installation commands updated
   - [ ] All URLs updated (or placeholders noted)

2. **CONTRIBUTING.md**
   - [ ] Project name updated
   - [ ] URLs updated

3. **CHANGELOG.md**
   - [ ] Project references updated

## Testing Specific Features

### Test Version Script

```bash
cd Scripts
./version.sh

# Should output something like:
# PigOS v25.x.x built from branch master at commit abc123...
```

### Test Path Variables

Check that paths are correctly set:

```bash
cd Scripts
source global_fn.sh
echo "Cache dir: $cacheDir"  # Should show .../pigos
echo "Config dir: $confDir"  # Should show ~/.config
```

### Test Uninstall Script (Dry Run)

**WARNING:** Don't actually run uninstall unless you want to remove PigOS!

```bash
cd Scripts
# Just check the script syntax
bash -n uninstall.sh
```

## Integration Testing

### Check Git Status

```bash
# See what files were changed
git status

# See the diff
git diff

# Check renamed files
git status --short | grep "^R"
```

### Verify File Structure

```bash
# Check that pigosvm directory exists
ls -la Scripts/pigosvm/

# Check that old hydevm is gone
ls Scripts/hydevm 2>&1  # Should show "No such file"

# Verify key files exist
test -f Scripts/pigosvm/pigosvm.sh && echo "✓ pigosvm.sh exists"
test -f Scripts/pigosvm/default.nix && echo "✓ default.nix exists"
test -f Scripts/pigosvm/README.md && echo "✓ README.md exists"
```

## Common Issues to Check

### 1. Missing Variable Updates

```bash
# Check for any remaining HYDE_ variables (except in comments)
grep -r "HYDE_" Scripts/ | grep -v "^#" | grep -v "PIGOS"
```

### 2. Path Mismatches

```bash
# Check for old path patterns
grep -r "/hyde" Scripts/ | grep -v "HyDE-Project" | grep -v "hyde-themes"
```

### 3. Broken References

```bash
# Check for broken file references
grep -r "hydevm" Scripts/ | grep -v "pigosvm"
```

## Quick Test Script

Create a test script to run all checks:

```bash
#!/bin/bash
# save as test_pigos.sh

echo "=== Testing PigOS Migration ==="
echo ""

echo "1. Checking for remaining 'hyde' references..."
hyde_refs=$(grep -r "hyde" Scripts/ --exclude-dir=.git 2>/dev/null | grep -v "HyDE-Project" | grep -v "hyde-themes" | grep -v "hyde-gallery" | wc -l)
if [ "$hyde_refs" -gt 0 ]; then
    echo "⚠️  Found $hyde_refs potential 'hyde' references"
else
    echo "✓ No problematic 'hyde' references found"
fi

echo ""
echo "2. Checking script syntax..."
cd Scripts
errors=0
for script in install.sh global_fn.sh version.sh; do
    if bash -n "$script" 2>/dev/null; then
        echo "✓ $script syntax OK"
    else
        echo "✗ $script has syntax errors"
        ((errors++))
    fi
done

echo ""
echo "3. Checking variable usage..."
if grep -q "PIGOS_LOG" install.sh; then
    echo "✓ PIGOS_LOG variable found"
else
    echo "✗ PIGOS_LOG variable missing"
    ((errors++))
fi

echo ""
echo "4. Checking directory structure..."
if [ -d "pigosvm" ]; then
    echo "✓ pigosvm directory exists"
else
    echo "✗ pigosvm directory missing"
    ((errors++))
fi

if [ ! -d "hydevm" ]; then
    echo "✓ old hydevm directory removed"
else
    echo "⚠️  old hydevm directory still exists"
fi

echo ""
if [ $errors -eq 0 ]; then
    echo "✅ All checks passed!"
else
    echo "❌ Found $errors issues"
fi
```

Run it:
```bash
chmod +x test_pigos.sh
./test_pigos.sh
```

## Next Steps After Testing

1. **If all tests pass:**
   - Update repository URLs (replace `YOUR-ORG`)
   - Commit your changes
   - Push to your repository

2. **If issues are found:**
   - Review the error messages
   - Check `IMPORT_REPORT.md` for guidance
   - Fix remaining references
   - Re-run tests

## Getting Help

If you encounter issues:

1. Check `IMPORT_REPORT.md` for detailed migration notes
2. Review the original HyDE repository for context
3. Check script error messages for specific issues
4. Use dry-run mode (`-t` flag) to see what would happen

---

**Remember:** Always test in a VM or dry-run mode before installing on your main system!

