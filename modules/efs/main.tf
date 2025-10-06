resource "aws_efs_file_system" "main" {
  creation_token   = "${var.project_name}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-efs"
  })
}

# EFS Mount Targets
resource "aws_efs_mount_target" "main" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = each.value
  security_groups = [var.security_group_id]
}