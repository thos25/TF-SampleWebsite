# sample-website
This is a sample website deployment to Azure App Services using Terraform.  This deployment will create the cloud infrastructure, create the CI/CD pipeline from Azure to Github, setup the Githb action to pull the source code and deploy to the App Service, and create the scaling rules to scale appropriately.  

# PreReqs

As of this writing, in order to leverage the azurerm_app_service_souce_control resource, you need to opt-in to the Azurerm module version 3.0 beta.  To do so, follow the steps here:

    - https://github.com/hashicorp/terraform-provider-azurerm/blob/main/website/docs/guides/3.0-beta.html.markdown

# Install

For this project you'll need the following

    -   Terraform v1.0.7
        -   Follow directions here <https://learn.hashicorp.com/tutorials/terraform/install-cli>
    -   Azure CLI
        -   Follow directions here <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli>
    -   Active Azure subscription
    -   GitHub Oauth token to <https://github.com/thos25/Sample-Website> for CI/CD Pipeline
        -   As of this writing the Oauth token needs to be made into an environment variable called "TF_VAR_Github_OAuth"


# Deploy

Clone the repo

    git clone https://github.com/thos25/TF-SampleWebsite.git

Login to Azure via Azure CLI

    az login

Initialize Terraform and download the correct modules

    terraform init

Plan the build

    terraform plan -out=tfplan

Run the build

    terraform apply tfplan

