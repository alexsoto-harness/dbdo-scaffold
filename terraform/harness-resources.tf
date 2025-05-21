resource "harness_platform_project" "project" {  
    name      = var.project_name 
    identifier = local.project_name  
    org_id    = "default"  
}
