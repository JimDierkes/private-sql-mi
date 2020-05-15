# Connect to Azure SQL MI using Port Forwarding VMs

This sample create a Virtual Machine Scale Set as Port Forwarder to an existent Azure SQL Managed Instance (SQL MI) in a Virtual Network.

## Running with Terraform locally
* Copy and paste file **terraform.tfvars** and name the new file **terraform.auto.tfvars** use this new file to set your local variables values. Terraform will use this file instead for local executions, for more information see [here](https://www.terraform.io/docs/configuration/variables.html#variable-definition-precedence). Here is a quick **terraform.auto.tfvars** example:

```hcl
prefix = "fwdsample"

environment_name = "dev"

location = "eastus2"

vm_username = "vmadmin"

vm_password = "<replace-me>"

vm_image_id = ""

vm_image_ref = {
      publisher = "RedHat"
      offer     = "RHEL"
      sku       = "7-RAW-CI"
      version   = "7.6.2019072418"
}

vm_size = "Standard_DS1_v2"

vmss_instances = 1

common_tags = {
    org_name    = "My Org"
    cost_center = "12345"
    project     = "port_fwd"
    project_id  = "12345"
    created_by  = "My Team"
}

# SQL MI target variables

sql_mi_fqdn = "<replace-me>"

vnet_rg_name = "<replace-me>"

vnet_name = "<replace-me>"

subnet_name = "<replace-me>"

```

* Run the following commands.

```bash
# Login into Azure
az login 
az account set -s <subscription-id>

# Run Terraform 
terraform init
terraform plan
terraform apply 
```

## Authors

Originally created by [Alejandra Guillen](http://github.com/aleguillen)

## License

[MIT](LICENSE)