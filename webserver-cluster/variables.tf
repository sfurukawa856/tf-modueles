variable "project" {
  description = "プロジェクト名"
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "instance_type" {
  description = "EC2インスタンスのインスタンスタイプ"
  type        = string
}

variable "subnet_ids" {
  description = "EC2インスタンスを設置するサブネットID"
  type        = list(string)
}
