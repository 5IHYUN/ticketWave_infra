terraform {
  backend "s3" {
    bucket       = "ticketwave-tfstate-5ihyun" # bootstrap-backend에서 생성
    key          = "dev/platform-addons/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
