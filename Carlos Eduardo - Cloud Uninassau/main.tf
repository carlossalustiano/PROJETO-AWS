provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "local_files" {
  bucket = "carloseduardo-local-files-bucket-20241028"
}

resource "aws_s3_bucket" "bronze" {
  bucket = "carloseduardo-bronze-bucket-20241028"
}

resource "aws_s3_bucket" "silver" {
  bucket = "carloseduardo-silver-bucket-20241028"
}

resource "aws_s3_bucket" "gold" {
  bucket = "carloseduardo-gold-bucket-20241028"
}

resource "aws_sns_topic" "file_notifications" {
  name = "file-notifications-topic"
}

resource "aws_sns_topic_policy" "sns_policy" {
  arn = aws_sns_topic.file_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "BronzeBucketNotification" 
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "SNS:Publish"
        Resource = aws_sns_topic.file_notifications.arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_s3_bucket.bronze.arn
          }
        }
      },
      {
        Sid = "SilverBucketNotification"  
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "SNS:Publish"
        Resource = aws_sns_topic.file_notifications.arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_s3_bucket.silver.arn
          }
        }
      },
      {
        Sid = "GoldBucketNotification" 
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "SNS:Publish"
        Resource = aws_sns_topic.file_notifications.arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_s3_bucket.gold.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue" "file_queue" {
  name                        = "file-notifications-queue"
  delay_seconds               = 0
  visibility_timeout_seconds   = 300
  message_retention_seconds    = 86400
  receive_wait_time_seconds    = 0
}

resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn = aws_sns_topic.file_notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.file_queue.arn
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.file_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.file_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.file_notifications.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "bronze_notification" {
  bucket = aws_s3_bucket.bronze.id

  topic {
    topic_arn = aws_sns_topic.file_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_notification" "silver_notification" {
  bucket = aws_s3_bucket.silver.id

  topic {
    topic_arn = aws_sns_topic.file_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_notification" "gold_notification" {
  bucket = aws_s3_bucket.gold.id

  topic {
    topic_arn = aws_sns_topic.file_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }
}