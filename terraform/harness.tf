terraform {  
    required_providers {  
        harness = {  
            source = "harness/harness"  
            version = "0.30.2"
        }  
    }  
}

variable "key" {
  description = "Harness Key"
  type        = string
  sensitive   = true

}

provider "harness" {  
    endpoint   = "https://app.harness.io/gateway"  
    account_id = "ifEKEGuIQQKy2ltl3Epatg"  
    platform_api_key    = var.key
}
