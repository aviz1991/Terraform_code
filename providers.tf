provider "aws" {
  profile = var.profile
  region  = var.my_region
  alias   = "my_region"

}
