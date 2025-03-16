# aws-normalized

This module creates missing resources in other aws partitions.

```tf
module "normalized" { source = "github.com/linolabx/tfmodules?ref=aws-normalized@v0.0.1" }
```

aws-cn missing resource list:

- `policy/IAMSelfManageServiceSpecificCredentials`
