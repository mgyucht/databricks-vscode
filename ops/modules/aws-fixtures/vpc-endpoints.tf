locals {
  // TODO: need to update this (and this is probably valid only for prod)
  pl_user_to_workspace = {
    "us-west-2" : "com.amazonaws.vpce.us-west-2.vpce-svc-0129f463fcfbc46c5",
    "us-east-1" : "com.amazonaws.vpce.us-east-1.vpce-svc-09143d1e626de2f04",
    "eu-west-1" : "com.amazonaws.vpce.eu-west-1.vpce-svc-0da6ebf1461278016",
  }
  
  pl_dataplane_to_controlplane = {
    "us-west-2" : "com.amazonaws.vpce.us-west-2.vpce-svc-0129f463fcfbc46c5"
    "us-east-1" : "com.amazonaws.vpce.us-east-1.vpce-svc-09143d1e626de2f04",
    # "eu-west-1": "com.amazonaws.vpce.eu-west-1.vpce-svc-0da6ebf1461278016",
    "eu-west-1" : "com.amazonaws.vpce.eu-west-1.vpce-svc-09b4eb2bc775f4e8c",
  }
}

resource "aws_vpc_endpoint" "relay" {
  service_name       = local.pl_dataplane_to_controlplane[var.region]
  vpc_id             = module.vpc.vpc_id
  vpc_endpoint_type  = "Interface"
  security_group_ids = [module.vpc.default_security_group_id]
  subnet_ids         = module.vpc.private_subnets
}
