variable "prefix" {
  type    = string
  default = "AWS-TFE"
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "instance_type1" {
  type    = string
  default = "t3.medium"
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
}

variable "AWS_ACCESS_KEY_ID" {
  type = string
}