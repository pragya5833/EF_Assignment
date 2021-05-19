variable "region"{
    default = "ap-south-1"
}
variable "amiId"{
    default = "ami-010aff33ed5991201"
}
variable "instanceType"{
    default ="t2.micro"
}
variable "handler" {
  default = "lambda.lambda_handler"
}
variable "runtime" {
  default = "python3.7"
}

variable "schedule_midnight" {
  default = "cron(0 0 * * ? *)"
}
