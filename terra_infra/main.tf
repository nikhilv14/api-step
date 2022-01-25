resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.iam_for_sfn.arn

  definition = <<EOF
{
  "StartAt": "getFunction",
  "States": {
    "getFunction": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "ResultSelector": {
        "Payload.$": "$.Payload"
      },
      "ResultPath": "$.fnc",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "arn:aws:lambda:eu-west-1:920416911834:function:xyz:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "prisma_request"
    },
    "prisma_request": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.fnc.Payload",
          "StringMatches": "s3_keys",
          "Next": "s3_keys"
        },
        {
          "Variable": "$.fnc.Payload",
          "StringMatches": "hostinfo",
          "Next": "access_keys"
        }
      ],
      "Default": "Incorrect Syntax"
    },
    "s3_keys": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "ResultSelector": {
        "Payload.$": "$.Payload"
      },
      "ResultPath": "$.toPresent",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "arn:aws:lambda:eu-west-1:920416911834:function:prisma_s3_keys:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Presentation Layer (for now via Power Automate)"
    },
        "Host Info": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "ResultSelector": {
        "Payload.$": "$.Payload"
      },
      "ResultPath": "$.toPresent",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "arn:aws:lambda:eu-west-1:920416911834:function:prisma_access_keys:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Presentation Layer (for now via Power Automate)"
    },
    "Presentation Layer (for now via Power Automate)": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "arn:aws:lambda:eu-west-1:920416911834:function:revertToUser:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Success"
    },
    "Success": {
      "Type": "Succeed"
    },
    "Incorrect Syntax": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "ResultSelector": {
        "Payload.$": "$.Payload"
      },
      "ResultPath": "$.toPresent",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "arn:aws:lambda:eu-west-1:920416911834:function:elseDefault:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Presentation Layer (for now via Power Automate)"
    }
  },
  "Comment": "prismabot state machine"
}

  EOF 
}

resource "aws_api_gateway_rest_api" "api-gateway-for-prismaStep" {
  name        = "prismaStep"
  description = "API to access step functions workflow for prisma"
  body        = "${data.template_file.prisma_api_swagger.rendered}"
}

resource "aws_api_gateway_deployment" "step-api-gateway-deployment" {
  rest_api_id = "${aws_api_gateway_rest_api.api-gateway-for-prismaStep.id}"
  stage_name  = "dev"
}

output "url" {
  value = "${aws_api_gateway_deployment.step-api-gateway-deployment.invoke_url}/startStepFunctions"
}