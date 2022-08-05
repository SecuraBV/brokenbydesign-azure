# Azure vulnerable application
<img width="759" alt="broken by design white" src="https://user-images.githubusercontent.com/14212955/180998359-a17af967-84bc-4541-af75-06a1ea4e5927.png">

A vulnerable Azure architecture that is online 24/7.
The environment provides several flags that can be found by exploiting Azure vulnerabilities.

## Links
- Link to tool is: https://brokenazure.cloud
- File issues at: https://github.com/SecuraBV/brokenbydesign-azure/issues
- Link to website source code is: https://github.com/SecuraBV/brokenbydesign-azure-website
- Created by: https://www.secura.com/

## Requirements for development
- [Azure CLI installed and in your $PATH](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform installed and in your $PATH](https://www.terraform.io/downloads)
- [SQL Command line installed and in your $PATH](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-ver16)
- [Azure Functions Core Tools installed and in your $PATH](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- sshpass installed and in your $PATH

## Running the Terraform scripts
1. Login using the `az login`
2. Make sure the certificates (`files/key.pem` and `files/cert.pem`) are still valid, currently untill 2032.
3. Run `terraform init` to install required providers
4. Run `terraform plan` to see changes (You can also skip this step)
5. Run `terraform apply` to apply changes
6. If you want to destroy the environment, run `Terraform destroy`

## Notes
- Certificate and key expire `Mar 19 14:36:57 2032 GMT`
- Make sure `Security defaults` is `disabled` (otherwise MFA is required on the DevOps user)
- Error: `The subscription is not registered to use namespace 'Microsoft.Sql'` please run `az provider register --namespace Microsoft.Sql`
- Error: `The subscription is not registered to use namespace 'Microsoft.Web'` please run `az provider register --namespace Microsoft.Web`

## Issues / to do
- DevOps user is able to modify own profile ex. password and MFA
  - Run a runbook script every hour to reset password and MFA
- DevOps user may leak IP adresses, geo-locations, browser version and OS type in profile settings
  - Reset whole environment (or only user) to minimize leaked information
- Maybe change cloudName (presented when logging in as service principal) to a flag?

## Creating new certificates
Run `openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem`. 
Make sure to add the application-id and tenant-id to the cert.pem in format:
```
-----BEGIN AZURE_DETAILS-----
Tenant id: TENANT_ID_HERE
App-id: APP_ID_HERE
-----END AZURE_DETAILS-----
```

