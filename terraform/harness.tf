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

provider "harness" {  
    endpoint   = "https://app.harness.io/gateway"  
    account_id = "ifEKEGuIQQKy2ltl3Epatg"  
    platform_api_key    = var.key
}
