#################################
# Editorial Web Frontend Server #
#################################
resource "aws_launch_template" "install_code_deploy_agent" {
  user_data = filebase64("${path.module}/scripts/install-codedeploy-agent.sh")
}

resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = "TBC"
}

resource "aws_instance" "frontend_server" {
  ami           = "ami-084e8c05825742534"
  launch_template {
    name = aws_launch_template.install_code_deploy_agent.name
  }
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.code_deploy_ec2_profile.name
  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name = "EditorialWeb"
  }
}
