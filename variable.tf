variable "create_usernames" {
  description = "A list of usernames to create on the instance"
  type        = list(string)
  default     = ["sp","sp1","sp2","sp3","sp4"]
}

variable "delete_usernames" {
  description = "A list of usernames to delete from the instance"
  type        = list(string)
  default     = ["sp2"]
}
