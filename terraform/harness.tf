terraform {  
    required_providers {  
        harness = {  
            source = "harness/harness"  
            version = "0.37.4"
        }  
    }  
}

variable "key" {
  description = "Harness Key"
  type        = string
  sensitive   = true

}

variable "account" {
  description = "Harness Account"
  type        = string
}

provider "harness" {  
    endpoint   = "https://app.harness.io/gateway"  
    account_id = var.account  
    platform_api_key    = var.key
}
