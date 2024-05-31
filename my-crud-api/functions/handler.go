package main

import (
	"context"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func routeRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	switch request.HTTPMethod {
	case "POST":
		return CreateHandler(ctx, request)
	case "GET":
		return ReadHandler(ctx, request)
	case "PUT":
		return UpdateHandler(ctx, request)
	case "DELETE":
		return DeleteHandler(ctx, request)
	default:
		return events.APIGatewayProxyResponse{StatusCode: 404, Body: "Not Found"}, nil
	}
}

func main() {
	lambda.Start(routeRequest)
}
