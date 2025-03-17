# local-volume

create local volume on specific-host

```tf
module "lotus_volume" {
  source = "github.com/linolabx/tfmodules?ref=k8s-local-volume@v0.0.1"

  namespace        = "staging"
  name             = "mysql-data-vol"
  storage_host     = "hpc-01"
  storage_endpoint = "k8s-nvme-01"
  capacity         = "2Ti"
}

module.local_volume.volume_path
# /mnt/k8s-nvme-01/volumes/staging.mysql-data-vol
```

this module expects the host has a local storage mounted on /mnt/storage_endpoint_name, and it creates directory /mnt/storage_endpoint_name/volumes/namespace.volume_name, the storage_host match the label "kubernetes.io/hostname" on the host.

## Requirements

| Name                                                                        | Version |
| --------------------------------------------------------------------------- | ------- |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement_kubernetes) | ~> 2.0  |

## Providers

| Name                                                                  | Version |
| --------------------------------------------------------------------- | ------- |
| <a name="provider_kubernetes"></a> [kubernetes](#provider_kubernetes) | ~> 2.0  |

## Modules

No modules.

## Resources

| Name                                                                                                                                                  | Type     |
| ----------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [kubernetes_persistent_volume.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume)             | resource |
| [kubernetes_persistent_volume_claim.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |

## Inputs

| Name                                                                                 | Description | Type           | Default                               | Required |
| ------------------------------------------------------------------------------------ | ----------- | -------------- | ------------------------------------- | :------: |
| <a name="input_access_modes"></a> [access_modes](#input_access_modes)                | n/a         | `list(string)` | <pre>[<br> "ReadWriteOnce"<br>]</pre> |    no    |
| <a name="input_capacity"></a> [capacity](#input_capacity)                            | n/a         | `string`       | n/a                                   |   yes    |
| <a name="input_host_path_type"></a> [host_path_type](#input_host_path_type)          | n/a         | `string`       | `"DirectoryOrCreate"`                 |    no    |
| <a name="input_name"></a> [name](#input_name)                                        | n/a         | `string`       | n/a                                   |   yes    |
| <a name="input_namespace"></a> [namespace](#input_namespace)                         | n/a         | `string`       | n/a                                   |   yes    |
| <a name="input_pv_reclaim_policy"></a> [pv_reclaim_policy](#input_pv_reclaim_policy) | n/a         | `string`       | `"Retain"`                            |    no    |
| <a name="input_storage_endpoint"></a> [storage_endpoint](#input_storage_endpoint)    | n/a         | `string`       | n/a                                   |   yes    |
| <a name="input_storage_host"></a> [storage_host](#input_storage_host)                | n/a         | `string`       | n/a                                   |   yes    |

## Outputs

| Name                                                                 | Description |
| -------------------------------------------------------------------- | ----------- |
| <a name="output_pvc_name"></a> [pvc_name](#output_pvc_name)          | n/a         |
| <a name="output_volume_name"></a> [volume_name](#output_volume_name) | n/a         |
| <a name="output_volume_path"></a> [volume_path](#output_volume_path) | n/a         |
