# Creating Lambda IAM Role
resource "aws_iam_role" "lambda_iam_role_name" {
	name = var.lambda_iam_role_name
	
	assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          Service: "lambda.amazonaws.com"
        },
        Action: "sts:AssumeRole"
      }
    ]
  })
}




# Lambda Role Policy details
resource "aws_iam_role_policy" "lambda_iam_policy_name" {
  	name = var.lambda_iam_policy_name
  	role = aws_iam_role.lambda_iam_role_name.id
	
	policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Action: [
          "s3:*",
          "sqs:*",
		      "rds:*"
        ],
        Effect: "Allow",
        Resource: "*"
      }
    ]
  })
}




# Lambda Function
resource "aws_lambda_function" "data_pipeline" {
	function_name 		= var.function_name
	role 				= aws_iam_role.lambda_iam_role_name.arn
	handler 			= "py/${var.handler_name}.lambda_handler"
	runtime 			= var.runtime
	timeout 			= var.timeout
	filename 			= "../py.zip"
	source_code_hash 	= filebase64sha256("../py.zip")
	environment {
		variables = {
		  	env = var.environment
			# buraya yeni variable lar girecek kendi kodum için
		}
	}
}





# AWS S3 Bucket Details
resource "aws_s3_bucket" "adducere_partner_bucket" {
	bucket 	= var.bucket_name
	
	tags = {
	  Environment = var.environment
	}

	lifecycle {
		prevent_destroy = false # bunu sonra TRUE'ya al
	}
}


resource "aws_s3_bucket_server_side_encryption_configuration" "adducere_s3_encrpytion_configuration" {
    bucket = aws_s3_bucket.adducere_partner_bucket.id

    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.adducere_s3_encrpytion
      }
    }  
}






# S3 Bucket to Lambda Triggering Permission
resource "aws_s3_bucket_notification" "s3-lambda-trigger" {
  bucket = aws_s3_bucket.adducere_partner_bucket.id
  lambda_function {
	  lambda_function_arn = aws_lambda_function.data_pipeline.arn
	  events 				      = ["s3:ObjectCreated:*"]
  }
}


resource "aws_lambda_permission" "trigger-permission" {
  statement_id 	= "AllowS3Invoke"
  action 		    = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_pipeline.function_name
  principal 	  = "s3.amazonaws.com"
  source_arn 	  = "arn:aws:s3:::${aws_s3_bucket.adducere_partner_bucket.id}"
}









# Queue for Customer order
resource "aws_sqs_queue" "customer_order_queue" {
  name                      	  = var.customer_queue
  fifo_queue                	  = true
  content_based_deduplication 	= true
  max_message_size          	  = 262144
  delay_seconds             	  = 0
  visibility_timeout_seconds	  = 30
  receive_wait_time_seconds 	  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.customer_queue_dlq.arn
    maxReceiveCount     = 5
  })
}

# Dead Letter Queue for Customer Order Queue
resource "aws_sqs_queue" "customer_queue_dlq" {
  name 							= var.customer_dlq
  fifo_queue                	  = true
  content_based_deduplication 	= true
  max_message_size          	  = 262144
  delay_seconds             	  = 0
  visibility_timeout_seconds	  = 30
  receive_wait_time_seconds 	  = 20
}


# Queue for Error Messages
resource "aws_sqs_queue" "error_queue" {
  name                        = var.error_queue
  fifo_queue                  = false
  max_message_size            = 262144
  delay_seconds               = 0
  visibility_timeout_seconds  = 30
  receive_wait_time_seconds   = 20
}

