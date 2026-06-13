# Troubleshooting Report Template

This document is used when a milestone fails during validation, deployment, or smoke testing.

The goal is to force a structured troubleshooting subprocess before repair work continues.

## 1. Failure Summary

Milestone:

Phase:

Timestamp:

Observed failure:

Expected behavior:

Actual behavior:

## 2. Scope Boundary

Is this likely one of the following?

- Application code issue
- Validation/test issue
- Local environment issue
- Deployment script issue
- Server/runtime issue
- DNS/network issue
- Secrets/configuration issue
- Database/service dependency issue
- Permission/user/group issue
- Disk/memory/resource issue
- Unknown

Chosen category:

Why:

## 3. Evidence Reviewed

List the evidence reviewed before making changes.

- Failure context file:
- Local logs:
- Server logs:
- Git diff:
- Git status:
- Relevant config files:
- Relevant application files:
- Relevant deployment files:

## 4. First Failing Command

Command:

Exit behavior:

Relevant output:

## 5. Root Cause Hypothesis

Primary hypothesis:

Supporting evidence:

Alternative hypotheses considered:

## 6. Safety Check Before Repair

Before making any changes, confirm:

- The fix is within the current milestone scope.
- The fix does not hardcode secrets.
- The fix does not remove or weaken tests.
- The fix does not bypass validation.
- The fix does not change production targets unless explicitly required.
- The fix does not hide a real infrastructure problem.

If any item is not true, stop and request manual intervention.

## 7. Repair Plan

Smallest safe change:

Files expected to change:

Commands to rerun:

Rollback plan:

## 8. Repair Result

Files changed:

Commands rerun:

Result:

Remaining risk:

## 9. Manual Intervention Required?

Answer yes/no:

If yes, describe exactly what the human must do:

