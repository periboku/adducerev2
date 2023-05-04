provider "aws" {
	region 						= var.region
	profile                 	= var.aws_profile
	shared_credentials_file 	= var.aws_path
}
