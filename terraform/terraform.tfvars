aws_region = [
          "eu-west-2",
          "us-east-1",
]

vpc_cidr = [ 
          "10.0.0.0/16",
          "10.1.0.0/16", 
]

subnet_cidr = [ 
          "10.0.0.0/24",
          "10.1.0.0/24",
 ]

prosimo_cidr = [
          "10.251.0.0/23",
          "10.252.0.0/23",
]

private_ip = [
          "10.0.0.100",
          "10.1.0.100",
]

cloud_type = "AWS"


US_East_FrontEnd = {
  VPC1 = {
    aws_vpc_name          = "WebSvcsProdUs1"
    igw_name              = "WebSvcsProdUs1-IGW"
    rt_name               = "WebSvcsProdUs1-RT"
    aws_subnet_name       = "WebSvcsProdUs1-subnet"
    private_ip            = "10.10.0.100"
    aws_ec2_name          = "WebServerProdUs1"
    aws_ec2_key_pair_name = "US_EAST_WebProd1"
    aws_vpc_cidr          = "10.10.0.0/24"
    aws_subnet_cidr       = "10.10.0.0/24"
  },

  VPC2 = {
    aws_vpc_name          = "WebSvcsProdUs2"
    igw_name              = "WebSvcsProdUs2-IGW"
    rt_name               = "WebSvcsProdUs2-RT"
    aws_subnet_name       = "WebSvcsProdUs2-subnet"
    private_ip            = "10.10.2.100"
    aws_ec2_name          = "WebServerProdUs2"
    aws_ec2_key_pair_name = "US_EAST_WebProd2"
    aws_vpc_cidr          = "10.10.2.0/24"
    aws_subnet_cidr       = "10.10.2.0/24"
  },

  VPC3 = {
    aws_vpc_name          = "WebSvcsProdUs3"
    igw_name              = "WebSvcsProdUs3-IGW"
    rt_name               = "WebSvcsProdUs3-RT"
    aws_subnet_name	  = "WebSvcsProdUs3-subnet"
    private_ip            = "10.10.3.100"
    aws_ec2_name          = "WebServerProdUs3"
    aws_ec2_key_pair_name = "US_EAST_WebProd3"
    aws_vpc_cidr          = "10.10.3.0/24"
    aws_subnet_cidr	  = "10.10.3.0/24"
  },
  VPC4 = {
    aws_vpc_name          = "WebSvcsPartnerUs"
    igw_name              = "WebSvcsPartnerUs-IGW"
    rt_name               = "WebSvcsPartnerUs-RT"
    aws_subnet_name	  = "WebSvcsPartnerUs-subnet"
    private_ip            = "10.10.0.100"
    aws_ec2_name          = "WebServerPartnerUs1"
    aws_ec2_key_pair_name = "US_EAST_WebPartnerUs1"
    aws_vpc_cidr          = "10.10.0.0/24"
    aws_subnet_cidr	  = "10.10.0.0/24"
  }
}

EU_West_FrontEnd = {
  VPC1 = {
    aws_vpc_name          = "WebSvcsProdEu1"
    igw_name              = "WebSvcsProdEu1-IGW"
    rt_name               = "WebSvcsProdEu1-RT"
    aws_subnet_name       = "WebSvcsProdEu1-Subnet"
    private_ip            = "10.20.0.100"
    app_fqdn              = "app1.infolab.com"
    aws_ec2_name          = "WebServerProdEu1"
    aws_ec2_key_pair_name = "EU_WEST_WebProd1"
    aws_vpc_cidr          = "10.20.0.0/24"
    aws_subnet_cidr       = "10.20.0.0/24"
  },

  VPC2 = {
    aws_vpc_name          = "WebSvcsProdEu2"
    igw_name              = "WebSvcsProdEu2-IGW"
    rt_name               = "WebSvcsProdEu2-RT"
    aws_subnet_name       = "WebSvcsProdEu2-Subnet"
    private_ip            = "10.20.2.100"
    app_fqdn              = "app2.infolab.com"
    aws_ec2_name          = "WebServerProdEu2"
    aws_ec2_key_pair_name = "EU_WEST_WebProd2"
    aws_vpc_cidr          = "10.20.2.0/24"
    aws_subnet_cidr       = "10.20.2.0/24"
  },

  VPC3 = {
    aws_vpc_name          = "WebSvcsProdEu3"
    igw_name              = "WebSvcsProdEu3-IGW"
    rt_name               = "WebSvcsProdEu3-RT"
    aws_subnet_name	  = "WebSvcsProdEu3-Subnet"
    private_ip            = "10.20.3.100"
    app_fqdn              = "app3.infolab.com"
    aws_ec2_name          = "WebServerProdEu3"
    aws_ec2_key_pair_name = "EU_WEST_WebProd3"
    aws_vpc_cidr          = "10.20.3.0/24"
    aws_subnet_cidr	  = "10.20.3.0/24"
  }
}

North_US_AppSvcs_VNets = {
  Vnet1 = {
    azure_resource_group        = "WebProdUs"
    azure_location              = "East US"
    azure_vnet_name             = "WebProdUs_Vnet"
    azure_subnet_name           = "WebProdUs_Vnet_subnet"
    azure_instance_name         = "WebProdUs"
    azure_vm_size               = "Standard_DS1_v2"
    azure_server_key_pair_name  = "Azure_Srv1"
    azure_admin_username        = "igorlinux"
    azure_admin_password        = "igorlinux"
    azure_subnet_cidr           = "10.10.1.0/24"
    azure_vnet_cidr             = "10.10.0.0/16"
    azure_private_ip            = "10.10.1.100"
  }
}


North_EU_AppSvcs_VNets = {
  Vnet1 = {
    azure_resource_group        = "WebProdEu1"
    azure_location              = "North Europe"
    azure_vnet_name             = "WebProdEu_Vnet1"
    azure_subnet_name           = "WebProdEu_Vnet_subnet1"
    azure_instance_name         = "WebprodEu1"
    azure_vm_size               = "Standard_DS2_v2"
    azure_server_key_pair_name  = "Azure_Srv1"
    azure_admin_username        = "igorlinux"
    azure_admin_password        = "igorlinux"
    azure_subnet_cidr           = "10.10.1.0/24"
    azure_vnet_cidr             = "10.10.0.0/16"
    azure_private_ip            = "10.10.1.100"
    enable_peering              = true
  },
  Vnet2 = {
    azure_resource_group        = "WebProdEu2"
    azure_location              = "North Europe"
    azure_vnet_name             = "WebProdEu_Vnet2"
    azure_subnet_name           = "WebProdEu_Vnet_subnet2"
    azure_instance_name         = "WebprodEu2"
    azure_vm_size               = "Standard_DS2_v2"
    azure_server_key_pair_name  = "Azure_Srv2"
    azure_admin_username        = "igorlinux"
    azure_admin_password        = "igorlinux"
    azure_subnet_cidr           = "10.30.1.0/24"
    azure_vnet_cidr             = "10.30.0.0/16"
    azure_private_ip            = "10.30.1.100"
    enable_peering              = true
  }
}

GCP_EU_North = {
  VPC1 = {
    gcp_region     = "europe-north1"
    gcp_zone       = "europe-north1-a"
    ssh_user       = "terraform"
    startup_script = "../scripts/gcp_user_data.sh"

    gcp_vpc_name         = "websvcsprodeu1"
    igw_name             = "Websvcs"
    rt_name              = "websvcsprodeu1-rt"
    gcp_subnet_name      = "websvcsprodeu1-subnet"
    gcp_private_ip       = "10.20.0.100"
    gcp_app_fqdn         = "app1.infolab.com"
    gcp_instance_name    = "webserverprodeu1"
    gcp_vm_key_pair_name = "eu_west_webprod1_gcp"
    gcp_vpc_cidr         = "10.20.0.0/24"
    gcp_subnet_cidr      = "10.20.0.0/24"

    labels = {
      environment   = "prod"
      resourceowner = "igor-racic"
    }
  }
}

route53_domain_name = "infolab.com"
enable_dns_records = true
