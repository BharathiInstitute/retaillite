# Error Knowledge Base — RetailLite

Track every production error here. This grows over time, ensuring no error happens twice.

## Active Errors

_No production errors yet (pre-launch)._

## Error Log

| Error ID | Date | Platform | Category | Severity | Description | Root Cause | Fix | Test Added | Checklist Point |
|----------|------|----------|----------|----------|-------------|------------|-----|------------|-----------------|
| _Example_ | _2026-03-15_ | _Android_ | _M_ | _HIGH_ | _Crash on empty price_ | _No input validation_ | _Added validation + error_ | _Yes_ | _M-16_ |

## Error Template

Use this for every new production error:

```
ERROR ID        : ERR-YYYY-NNN
DATE DETECTED   :
DETECTED BY     : Crashlytics / User Report / Monitoring / Developer
PLATFORM        : Android / Web / Windows
SEVERITY        : CRITICAL / HIGH / MEDIUM / LOW

WHAT HAPPENED   :
EXPECTED        :
USERS AFFECTED  :
ERROR MESSAGE   :
STACK TRACE     :

DEVICE INFO     :
  - Device Model:
  - OS Version:
  - App Version:
  - Network Type:
  - Browser (if web):

STEPS TO REPRODUCE:
  1.
  2.
  3.

ROOT CAUSE      :
CATEGORY        : [A-S]
FIX DESCRIPTION :
TEST ADDED      : Yes / No (describe test)
CHECKLIST POINT : [Category]-[Number]
SCAN RESULTS    : [Were similar patterns found elsewhere? What was fixed?]
```
