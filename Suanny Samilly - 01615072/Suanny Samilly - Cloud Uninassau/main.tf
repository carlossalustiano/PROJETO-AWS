provider "aws" {
  region = "us-east-1"
}

# Buckets S3
resource "aws_s3_bucket" "local_files" {
  bucket = "suanny-local-files-bucket-38932784"
  acl    = "private"
}

resource "aws_s3_bucket" "bronze" {
  bucket = "suanny-bronze-bucket-38932784"
  acl    = "private"
}

resource "aws_s3_bucket" "silver" {
  bucket = "suanny-silver-bucket-38932784"
  acl    = "private"
}

resource "aws_s3_bucket" "gold" {
  bucket = "suanny-gold-bucket-38932784"
  acl    = "private"
}

# SNS Topic
resource "aws_sns_topic" "file_notifications" {
  name = "file-notifications-topic"
}

# SNS Topic Policy (Permite que o S3 publique mensagens no SNS)
resource "aws_sns_topic_policy" "sns_policy" {
  arn = aws_sns_topic.file_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3ToPublish"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.file_notifications.arn
      }
    ]
  })
}

# SQS Queue
resource "aws_sqs_queue" "file_queue" {
  name                        = "file-notifications-queue"
  delay_seconds               = 0
  visibility_timeout_seconds  = 300
  message_retention_seconds   = 86400
  receive_wait_time_seconds   = 0
}

# SNS Subscription to SQS Queue
resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn = aws_sns_topic.file_notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.file_queue.arn
}

# SQS Queue Policy (Permite que o SNS envie mensagens para a fila SQS)
resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.file_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSNSPublish"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.file_queue.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_sns_topic.file_notifications.arn }
        }
      }
    ]
  })
}

# S3 Bucket Notifications (para o bucket bronze)
resource "aws_s3_bucket_notification" "bronze_notification" {
  bucket = aws_s3_bucket.bronze.id

  topic {
    topic_arn = aws_sns_topic.file_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.sns_policy]
}

# S3 Bucket Notifications (para o bucket silver)
resource "aws_s3_bucket_notification" "silver_notification" {
  bucket = aws_s3_bucket.silver.id

  topic {
    topic_arn = aws_sns_topic.file_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.sns_policy]
}

# S3 Bucket Notifications (para o bucket gold)
resource "aws_s3_bucket_notification" "gold_notification" {
  bucket = aws_s3_bucket.gold.id

  topic {
    topic_arn = aws_sns_topic.file_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.sns_policy]
}