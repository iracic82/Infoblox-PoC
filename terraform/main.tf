locals {
  GCP_EU_North_final = {
    for k, v in var.GCP_EU_North : k => merge(v, {
      gcp_project = var.projectid
    })
  }
}

# Create EC2 and Networking Infrastructure in AWS

module "aws__instances_eu" {
  source = "./modules/aws-resources"
  providers         = {   
  aws = aws.eu-west-2
  }
  for_each              = var.EU_West_FrontEnd
  aws_region            = var.aws_region[0]
  aws_vpc_name          = each.value["aws_vpc_name"]
  aws_subnet_name       = each.value["aws_subnet_name"]
  rt_name               = each.value["rt_name"]
  igw_name              = each.value["igw_name"]
  private_ip            = each.value["private_ip"]
  tgw                   = "false"
  internet              = "true"
  aws_ec2_name          = each.value["aws_ec2_name"]
  aws_ec2_key_pair_name = each.value["aws_ec2_key_pair_name"]

  aws_vpc_cidr    = each.value["aws_vpc_cidr"]
  aws_subnet_cidr = each.value["aws_subnet_cidr"]
 
}


module "aws__instances_us" {
  source = "./modules/aws-resources"
  providers         = { 
  aws = aws.us-east-1
  }
  for_each              = var.US_East_FrontEnd
  aws_region            = var.aws_region[1]
  aws_vpc_name          = each.value["aws_vpc_name"]
  aws_subnet_name       = each.value["aws_subnet_name"]
  rt_name               = each.value["rt_name"]
  igw_name              = each.value["igw_name"]
  private_ip            = each.value["private_ip"]
  tgw                   = "false"
  internet              = "false"
  aws_ec2_name          = each.value["aws_ec2_name"]
  aws_ec2_key_pair_name = each.value["aws_ec2_key_pair_name"]

  aws_vpc_cidr    = each.value["aws_vpc_cidr"]
  aws_subnet_cidr = each.value["aws_subnet_cidr"]

}

# Create Linux and Networking Infrastructure in Azure

module "azure_instances_us" {
  source = "./modules/azure-resources"
  providers = {
  azurerm = azurerm.eun
  }
  for_each             = var.North_US_AppSvcs_VNets
  azure_resource_group = each.value["azure_resource_group"]
  azure_location       = "North Europe"
  azure_vnet_name      = each.value["azure_vnet_name"]
  azure_subnet_name    = each.value["azure_subnet_name"]
  azure_instance_name  = each.value["azure_instance_name"]
  azure_private_ip     = each.value["azure_private_ip"]
  azure_server_key_pair_name  = each.value["azure_server_key_pair_name"]
  azure_vm_size        = "Standard_DS2_v2"
  azure_admin_username = "linuxuser"
  azure_admin_password = "admin123"
  enable_peering = each.value["enable_peering"]

  azure_subnet_cidr    = each.value["azure_subnet_cidr"]
  azure_vnet_cidr      = each.value["azure_vnet_cidr"]
}


module "azure_instances_eu" {
  source = "./modules/azure-resources"
  providers = {
  azurerm = azurerm.eun
  }
  for_each             = var.North_EU_AppSvcs_VNets
  azure_resource_group = each.value["azure_resource_group"]
  azure_location       = "North Europe"
  azure_vnet_name      = each.value["azure_vnet_name"]
  azure_subnet_name    = each.value["azure_subnet_name"]
  azure_instance_name  = each.value["azure_instance_name"]
  azure_private_ip     = each.value["azure_private_ip"]
  azure_server_key_pair_name  = each.value["azure_server_key_pair_name"]
  azure_vm_size        = "Standard_DS1_v2"
  azure_admin_username = "linuxuser"
  azure_admin_password = "admin123"
  enable_peering = each.value["enable_peering"]

  azure_subnet_cidr    = each.value["azure_subnet_cidr"]
  azure_vnet_cidr      = each.value["azure_vnet_cidr"]
}


# Create Linux and Networking Infrastructure in GCP

module "gcp_instances" {
  source   = "./modules/gcp-resources"
  for_each = local.GCP_EU_North_final
  providers = {
    google = google.gcp_instances
  }

  project         = each.value["gcp_project"]
  region          = each.value["gcp_region"]
  zone            = each.value["gcp_zone"]

  vpc_name        = each.value["gcp_vpc_name"]
  subnet_name     = each.value["gcp_subnet_name"]
  subnet_cidr     = each.value["gcp_subnet_cidr"]
  private_ip      = each.value["gcp_private_ip"]
  instance_name   = each.value["gcp_instance_name"]

  startup_script = each.value["startup_script"] # just the string path
  ssh_user        = each.value["ssh_user"]

  labels          = each.value["labels"]
}



resource "aws_ec2_transit_gateway" "us" {
provider = aws.us-east-1
description = "AIG-US-TGW"
tags = {
    Name = "AIG-US-TGW"
  }
}




resource "aws_ec2_transit_gateway" "eu" {
provider = aws.eu-aws
description = "EU-TGW"
tags = {
    Name = "EU-TGW"
  }
}



# Create TGW Route Table

resource "aws_ec2_transit_gateway_route_table" "tgw_rt" {
  provider = aws.eu-aws
  transit_gateway_id = aws_ec2_transit_gateway.eu.id

  tags = {
    Name = "EU-TGW-RouteTable"
  }
}

# Attach multiple VPCs to TGW using for_each

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachments" {
  provider            = aws.eu-aws
  for_each            = module.aws__instances_eu  # ✅ Loops through ALL VPCs
  subnet_ids          = [each.value.subnet_id]
  transit_gateway_id  = aws_ec2_transit_gateway.eu.id
  vpc_id              = each.value.aws_vpc_id

  appliance_mode_support = "enable"
  dns_support            = "enable"
  ipv6_support           = "disable"

  tags = {
    Name = "${each.value.aws_vpc_name}-TGW-Attachment"
  }
}

# Associate ALL VPC Attachments with the TGW Route Table
#resource "aws_ec2_transit_gateway_route_table_association" "tgw_rt_associations" {
# provider = aws.eu-aws
#  for_each = aws_ec2_transit_gateway_vpc_attachment.tgw_attachments  # ✅ Loops through ALL TGW attachments

#  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
#  transit_gateway_attachment_id  = each.value.id
#}

# Create Routes in each VPC to send traffic to TGW
resource "aws_route" "tgw_routes" {
  provider = aws.eu-aws
  for_each              = module.aws__instances_eu
  route_table_id        = each.value.rt_id
  destination_cidr_block = "10.20.0.0/16"  # Adjust as needed
  transit_gateway_id     = aws_ec2_transit_gateway.eu.id
}

# Add routes in TGW Route Table for each VPC
resource "aws_ec2_transit_gateway_route" "tgw_routes" {
  provider = aws.eu-aws
  for_each = module.aws__instances_eu  # ✅ Loops through all VPCs

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
  destination_cidr_block         = each.value.aws_vpc_cidr  # ✅ Ensure it routes correctly
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attachments[each.key].id
}

/*
# Create TGW Route Table
resource "aws_ec2_transit_gateway_route_table" "tgw_rt" {
  provider = aws.eu-aws
  transit_gateway_id = aws_ec2_transit_gateway.eu.id
  tags = {
    Name = "EU-TGW-RouteTable"
  }
}

# Associate VPC1 Route Table with TGW Route Table
resource "aws_ec2_transit_gateway_route_table_association" "tgw_rt_association" {
  provider = aws.us-east-1
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rt.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id
}

# Attach ONLY WebSvcsProdUs1 (VPC1) to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  provider = aws.us-east-1
  subnet_ids          = [module.aws__instances_us["VPC1"].subnet_id]
  transit_gateway_id  = aws_ec2_transit_gateway.us.id
  vpc_id              = module.aws__instances_us["VPC1"].aws_vpc_id

  appliance_mode_support = "enable"
  dns_support            = "enable"
  ipv6_support           = "disable"

  tags = {
    Name = "${module.aws__instances_us["VPC1"].aws_vpc_name}-TGW-Attachment"
  }
}

# Add a route in VPC1's Route Table to send traffic to TGW
resource "aws_route" "tgw_route_vpc1" {
  provider = aws.us-east-1
  route_table_id         = module.aws__instances_us["VPC1"].rt_id
  destination_cidr_block = "10.10.0.0/16"  # Adjust for inter-VPC communication
  transit_gateway_id     = aws_ec2_transit_gateway.us.id
}

*/



resource "aws_route53_zone" "private_zone" {
  provider = aws.eu-west-2
  name     = var.route53_domain_name
  comment  = "Private hosted zone for Infoblox"

  dynamic "vpc" {
    for_each = { for key, data in module.aws__instances_eu : key => data.aws_vpc_id }  # Extract only VPC IDs
    content {
      vpc_id     = vpc.value
      vpc_region = var.aws_region[0]
    }
  }

  tags = {
    Name          = "InfobloxPrivateZone"
    ResourceOwner = "iracic@infoblox.com"
  }
}

resource "aws_route53_record" "dns_records" {

  provider = aws.eu-west-2
  count   = var.enable_dns_records ? length(keys(var.EU_West_FrontEnd)) : 0
  zone_id = aws_route53_zone.private_zone.id

  name = lookup(var.EU_West_FrontEnd[element(keys(var.EU_West_FrontEnd), count.index)], "app_fqdn", "default.infoblox.local")
  type = "A"
  ttl  = 300

  records = [
    lookup(
      var.EU_West_FrontEnd[element(keys(var.EU_West_FrontEnd), count.index)],
      "private_ip",
      "10.0.0.1"
    )
  ]
}

resource "aws_s3_bucket" "infoblox_poc" {

  provider = aws.eu-west-2
  bucket = "infoblox-poc-iracic"

  tags = {
    Name          = "Infoblox POC Bucket"
    Environment   = "POC"
    ResourceOwner = "iracic@infoblox.com"
  }
}

resource "aws_s3_bucket_public_access_block" "infoblox_poc" {

  provider = aws.eu-west-2
  bucket = aws_s3_bucket.infoblox_poc.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_access" {

  provider = aws.eu-west-2
  bucket = aws_s3_bucket.infoblox_poc.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.infoblox_poc.bucket}/uploads/*"
    }
  ]
}
EOF
}

resource "aws_s3_object" "uploaded_image" {

  provider = aws.eu-west-2
  bucket = aws_s3_bucket.infoblox_poc.id
  key    = "uploads/image.png"
  source = "/root/infoblox-lab/Infoblox-PoC/scripts/images/image.png"

  tags = {
    Name          = "Infoblox Image"
    ResourceOwner = "iracic@infoblox.com"
  }
}

resource "aws_route53_record" "s3_cname" {

  provider = aws.eu-west-2
  zone_id = aws_route53_zone.private_zone.id  # Use the correct hosted zone
  name    = "infobloxs3.infolab.com"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_s3_bucket.infoblox_poc.bucket}.s3.eu-west-2.amazonaws.com"]
}

# Azure DNS and Record creation

resource "azurerm_private_dns_zone" "private_dns_zone" {
  provider = azurerm.eun
  name                = "infolab.com"  # Update this if needed
  resource_group_name = module.azure_instances_eu["Vnet1"].azure_resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "eu_vnet_links" {
  provider = azurerm.eun
  for_each = module.azure_instances_eu  # Now using module output directly

  name                  = "${each.key}-dns-link"
  resource_group_name   = azurerm_private_dns_zone.private_dns_zone.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = each.value.azure_vnet_id  # Correctly referencing the output
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "eu_dns_records" {
  provider = azurerm.eun
  for_each = var.North_EU_AppSvcs_VNets

  name                = "azure-${lower(each.value.azure_instance_name)}" # Use instance name as the FQDN
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = var.North_EU_AppSvcs_VNets["Vnet1"].azure_resource_group
  ttl                 = 300
  records             = [each.value.azure_private_ip]
}

# Build connectivity across Vnets in Azure

resource "azurerm_virtual_network_peering" "vnet_peering" {
  provider = azurerm.eun

  for_each = {
    for key1, vnet1 in module.azure_instances_eu :
    key1 => {
      peers = {
        for key2, vnet2 in module.azure_instances_eu : key2 => vnet2
        if key1 != key2 && vnet1.enable_peering && vnet2.enable_peering  # ✅ Only peer enabled VNets
      }
    } if vnet1.enable_peering
  }

  name                         = "peering-${each.key}-to-${keys(each.value.peers)[0]}"
  resource_group_name          = module.azure_instances_eu[each.key].azure_resource_group_name
  virtual_network_name         = module.azure_instances_eu[each.key].azure_vnet_name
  remote_virtual_network_id    = module.azure_instances_eu[keys(each.value.peers)[0]].azure_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

/*
resource "azurerm_route_table" "vnet_route" {
  provider            = azurerm.eun
  for_each            = { for k, v in module.azure_instances_eu : k => v if v.enable_peering }
  name                = "route-${each.key}"
  location            = module.azure_instances_eu[each.key].azure_location
  resource_group_name = module.azure_instances_eu[each.key].azure_resource_group_name
}

resource "azurerm_route" "peered_route" {
  provider = azurerm.eun
  for_each = { for k, v in module.azure_instances_eu : k => v if v.enable_peering }

  name                = "route-${each.key}"
  resource_group_name = module.azure_instances_eu[each.key].azure_resource_group_name
  route_table_name    = azurerm_route_table.vnet_route[each.key].name
  address_prefix      = "10.0.0.0/8"  # 🔹 Modify this based on your IP ranges
  next_hop_type       = "VirtualNetworkGateway"
}
*/
