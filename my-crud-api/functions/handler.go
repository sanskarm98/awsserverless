package main

import (
	"context"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type Response struct {
	Message string `json:"message"`
}

func routeRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	switch request.Resource {
	case "/create":
		return CreateHandler(ctx, request)
	case "/read":
		return ReadHandler(ctx, request)
	case "/update":
		return UpdateHandler(ctx, request)
	case "/delete":
		return DeleteHandler(ctx, request)
	default:
		return events.APIGatewayProxyResponse{StatusCode: 404, Body: "Not Found"}, nil
	}
}

func main() {
	lambda.Start(routeRequest)
}
