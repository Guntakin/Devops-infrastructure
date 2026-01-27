locals {
  Node_name_1               = "Test_Server"
  Node_instance_type        = "t2.micro"
  nodes_ami                 = "ami-0159172a5a821bafd" // Windows_Server-2019-English-Full-Base-2022.11.10
  vpc_subnet_id             = "subnet-0fc44e66bb629dab6"
  availability_zone         = "us-east-1b"
  vpc_security_group_ids    = ["sg-028251f575b1f2111", "sg-057cd7d867371f36d", "sg-0dd1c415e1ff9c692", "sg-01bd6f20be6bd7699"]
  rms-installer_snapshot_id = "snap-022471dc1a1fb3400"
  model_data_snapshot_id    = ""
  environment               = "ICM-Starwind" //stage, etc.
  application_version       = "riskbrowser_v23"
  attach_installer_files    = true
}
module "RB-1" {
  source                 = "../../../terraform-modules/ec2_instance"
  name                   = local.Node_name_1
  ami                    = local.nodes_ami
  instance_type          = local.Node_instance_type
  key_name               = "icg-jenkins"
  monitoring             = true
  vpc_security_group_ids = local.vpc_security_group_ids
  subnet_id              = local.vpc_subnet_id
  tags = {
    terraform   = "true"
    environment = local.environment
    role        = local.application_version
  }
  enable_volume_tags = true
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 100
      tags = {
        Name = local.Node_name_1
      }
    },
  ]

}
