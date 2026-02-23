# Release PR: SDAF 3.19.0.0

## Problem

The SAP Deployment Automation Framework required several critical improvements across multiple dimensions:

1. **DevOps Integration Gaps** - Limited support for GitHub Actions workflows and inconsistent Azure App Configuration handling across deployment pipelines
2. **Platform Support** - Missing support for Ubuntu 25.04 and incomplete Oracle Grid infrastructure provisioning
3. **Deployment Reliability** - Key vault reference inconsistencies in managed DevOps scenarios causing deployment failures
4. **Configuration Management** - Fragmented approach to storing and retrieving deployment parameters across control plane and workload zones
5. **Infrastructure Gaps** - Missing marketplace plan configurations for observer VMs and incomplete Azure App Configuration integration

## Solution

### DevOps & Automation

### Infrastructure & Platform Support
- **RedHat 10 Support**: Support for RedHat 10 for the SAP deployments

### Deployment Reliability

### Configuration & Usability

### Bug Fixes

## Tests

### Prerequisites
- Azure subscription with appropriate permissions
- Ubuntu 24.04 test environment (if testing platform support)
- GitHub repository with Actions enabled (for GitHub Actions testing)

### Test Scenarios

**1. GitHub Actions Setup**
```bash
cd deploy/scripts/py_scripts/SDAF-GitHub-Actions
python New-SDAFGitHubActions.py
# Verify: GitHub Actions workflows created, repository variables configured, Terraform version set to 1.14
```

```

## Notes

### Breaking Changes
- None identified - this release maintains backward compatibility with existing deployments

### Migration Considerations
- Existing deployments can upgrade in place
- New Terraform 1.14.0 version requires validation of provider compatibility in custom modules
- App Configuration integration is additive and does not affect existing deployments without App Configuration

### Known Limitations
- Docker container support for GitHub Actions is experimental and requires container registry access
- Ubuntu 25.04 support is based on pre-release repositories which may change

### Dependencies Updated
This release includes multiple dependency version bumps:
- actions/checkout: 5.0.0 → 5.0.1
- actions/upload-artifact: 4.6.2 → 5.0.0 (major version bump)
- github/codeql-action: 4.31.1 → 4.31.3
- actions/dependency-review-action: 4.8.1 → 4.8.2
- step-security/harden-runner: 2.13.1 → 2.13.2
- Azure.ResourceManager.Compute: 1.12.0 → 1.13.0
- System.Runtime.Caching: 9.0.10 → 10.0.0 (major version bump)
- NuGet.Packaging: 6.14.0 → 7.0.0 (major version bump)
- dotnet-ef: 9.0.6 → 10.0.0 (major version bump)

### Contributor Recognition
This release includes contributions from:
- Kimmo Forss (@kimforss)
- Nadeen Noaman (@nnoaman)
- Copilot (code review and suggestions)
- hdamecharla (@hdamecharla)
 