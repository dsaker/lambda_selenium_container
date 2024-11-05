variable "ecr_name" {
  description = "The ecr name to create"
  type        = string
  default     = null
}

variable "lambda_function_name" {
  description = "The name of your lambda function"
  type        = string
  default     = null
}

variable "docker_image_tag" {
  description = "The tag for the docker image"
  type        = string
  default     = "latest"
}

variable "from_email" {
  description = "The verified email that will send email"
  type        = string
  sensitive = true
}

variable "to_email" {
  description = "The verified email that will receive email"
  type        = string
  sensitive = true
}

variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}
variable "image_mutability" {
  description = "Provide image mutability"
  type        = string
  default     = "MUTABLE"
}