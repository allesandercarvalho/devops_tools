package services

import (
	"context"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/aws/aws-sdk-go-v2/service/lambda"
	"github.com/aws/aws-sdk-go-v2/service/rds"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/devopstools/backend/internal/logger"
)

// AWSBrowserService handles AWS resource browsing using AWS SDK
type AWSBrowserService struct{}

// NewAWSBrowserService creates a new AWS browser service
func NewAWSBrowserService() *AWSBrowserService {
	return &AWSBrowserService{}
}

// S3Bucket represents an S3 bucket
type S3Bucket struct {
	Name         string    `json:"name"`
	CreationDate time.Time `json:"creation_date"`
	Region       string    `json:"region,omitempty"`
}

// S3Object represents an S3 object
type S3Object struct {
	Key          string    `json:"key"`
	Size         int64     `json:"size"`
	LastModified time.Time `json:"last_modified"`
	StorageClass string    `json:"storage_class"`
	IsFolder     bool      `json:"is_folder"`
}

// EC2Instance represents an EC2 instance
type EC2Instance struct {
	InstanceID       string    `json:"instance_id"`
	InstanceType     string    `json:"instance_type"`
	State            string    `json:"state"`
	PublicIP         string    `json:"public_ip,omitempty"`
	PrivateIP        string    `json:"private_ip,omitempty"`
	LaunchTime       time.Time `json:"launch_time"`
	Name             string    `json:"name,omitempty"`
	AvailabilityZone string    `json:"availability_zone"`
}

// RDSInstance represents an RDS database instance
type RDSInstance struct {
	DBInstanceIdentifier string    `json:"db_instance_identifier"`
	DBInstanceClass      string    `json:"db_instance_class"`
	Engine               string    `json:"engine"`
	EngineVersion        string    `json:"engine_version"`
	Status               string    `json:"status"`
	Endpoint             string    `json:"endpoint,omitempty"`
	Port                 int32     `json:"port"`
	AllocatedStorage     int32     `json:"allocated_storage"`
	CreatedTime          time.Time `json:"created_time"`
}

// LambdaFunction represents a Lambda function
type LambdaFunction struct {
	FunctionName string    `json:"function_name"`
	Runtime      string    `json:"runtime"`
	Handler      string    `json:"handler"`
	CodeSize     int64     `json:"code_size"`
	MemorySize   int32     `json:"memory_size"`
	Timeout      int32     `json:"timeout"`
	LastModified time.Time `json:"last_modified"`
	Description  string    `json:"description,omitempty"`
}

// loadAWSConfig loads AWS configuration with optional profile
func (s *AWSBrowserService) loadAWSConfig(ctx context.Context, profile string, region string) (aws.Config, error) {
	var opts []func(*config.LoadOptions) error

	if profile != "" {
		opts = append(opts, config.WithSharedConfigProfile(profile))
	}

	if region != "" {
		opts = append(opts, config.WithRegion(region))
	}

	cfg, err := config.LoadDefaultConfig(ctx, opts...)
	if err != nil {
		return aws.Config{}, fmt.Errorf("failed to load AWS config: %w", err)
	}

	return cfg, nil
}

// ListS3Buckets lists all S3 buckets
func (s *AWSBrowserService) ListS3Buckets(ctx context.Context, profile string) ([]S3Bucket, error) {
	cfg, err := s.loadAWSConfig(ctx, profile, "")
	if err != nil {
		return nil, err
	}

	client := s3.NewFromConfig(cfg)
	result, err := client.ListBuckets(ctx, &s3.ListBucketsInput{})
	if err != nil {
		logger.Error("Failed to list S3 buckets", err)
		return nil, fmt.Errorf("failed to list S3 buckets: %w", err)
	}

	buckets := make([]S3Bucket, 0, len(result.Buckets))
	for _, bucket := range result.Buckets {
		buckets = append(buckets, S3Bucket{
			Name:         aws.ToString(bucket.Name),
			CreationDate: aws.ToTime(bucket.CreationDate),
		})
	}

	logger.Info(fmt.Sprintf("Listed %d S3 buckets", len(buckets)))
	return buckets, nil
}

// ListS3Objects lists objects in an S3 bucket with optional prefix
func (s *AWSBrowserService) ListS3Objects(ctx context.Context, profile, bucket, prefix string) ([]S3Object, error) {
	cfg, err := s.loadAWSConfig(ctx, profile, "")
	if err != nil {
		return nil, err
	}

	client := s3.NewFromConfig(cfg)

	input := &s3.ListObjectsV2Input{
		Bucket: aws.String(bucket),
	}

	if prefix != "" {
		input.Prefix = aws.String(prefix)
		input.Delimiter = aws.String("/")
	} else {
		input.Delimiter = aws.String("/")
	}

	result, err := client.ListObjectsV2(ctx, input)
	if err != nil {
		logger.Error(fmt.Sprintf("Failed to list objects in bucket %s", bucket), err)
		return nil, fmt.Errorf("failed to list objects: %w", err)
	}

	objects := make([]S3Object, 0)

	// Add folders (common prefixes)
	for _, prefix := range result.CommonPrefixes {
		objects = append(objects, S3Object{
			Key:      aws.ToString(prefix.Prefix),
			IsFolder: true,
		})
	}

	// Add files
	for _, obj := range result.Contents {
		objects = append(objects, S3Object{
			Key:          aws.ToString(obj.Key),
			Size:         aws.ToInt64(obj.Size),
			LastModified: aws.ToTime(obj.LastModified),
			StorageClass: string(obj.StorageClass),
			IsFolder:     false,
		})
	}

	logger.Info(fmt.Sprintf("Listed %d objects in bucket %s", len(objects), bucket))
	return objects, nil
}

// ListEC2Instances lists all EC2 instances
func (s *AWSBrowserService) ListEC2Instances(ctx context.Context, profile, region string) ([]EC2Instance, error) {
	if region == "" {
		region = "us-east-1" // Default region
	}

	cfg, err := s.loadAWSConfig(ctx, profile, region)
	if err != nil {
		return nil, err
	}

	client := ec2.NewFromConfig(cfg)
	result, err := client.DescribeInstances(ctx, &ec2.DescribeInstancesInput{})
	if err != nil {
		logger.Error("Failed to list EC2 instances", err)
		return nil, fmt.Errorf("failed to list EC2 instances: %w", err)
	}

	instances := make([]EC2Instance, 0)
	for _, reservation := range result.Reservations {
		for _, instance := range reservation.Instances {
			// Get instance name from tags
			name := ""
			for _, tag := range instance.Tags {
				if aws.ToString(tag.Key) == "Name" {
					name = aws.ToString(tag.Value)
					break
				}
			}

			instances = append(instances, EC2Instance{
				InstanceID:       aws.ToString(instance.InstanceId),
				InstanceType:     string(instance.InstanceType),
				State:            string(instance.State.Name),
				PublicIP:         aws.ToString(instance.PublicIpAddress),
				PrivateIP:        aws.ToString(instance.PrivateIpAddress),
				LaunchTime:       aws.ToTime(instance.LaunchTime),
				Name:             name,
				AvailabilityZone: aws.ToString(instance.Placement.AvailabilityZone),
			})
		}
	}

	logger.Info(fmt.Sprintf("Listed %d EC2 instances", len(instances)))
	return instances, nil
}

// ListRDSInstances lists all RDS database instances
func (s *AWSBrowserService) ListRDSInstances(ctx context.Context, profile, region string) ([]RDSInstance, error) {
	if region == "" {
		region = "us-east-1"
	}

	cfg, err := s.loadAWSConfig(ctx, profile, region)
	if err != nil {
		return nil, err
	}

	client := rds.NewFromConfig(cfg)
	result, err := client.DescribeDBInstances(ctx, &rds.DescribeDBInstancesInput{})
	if err != nil {
		logger.Error("Failed to list RDS instances", err)
		return nil, fmt.Errorf("failed to list RDS instances: %w", err)
	}

	instances := make([]RDSInstance, 0, len(result.DBInstances))
	for _, db := range result.DBInstances {
		endpoint := ""
		if db.Endpoint != nil {
			endpoint = aws.ToString(db.Endpoint.Address)
		}

		instances = append(instances, RDSInstance{
			DBInstanceIdentifier: aws.ToString(db.DBInstanceIdentifier),
			DBInstanceClass:      aws.ToString(db.DBInstanceClass),
			Engine:               aws.ToString(db.Engine),
			EngineVersion:        aws.ToString(db.EngineVersion),
			Status:               aws.ToString(db.DBInstanceStatus),
			Endpoint:             endpoint,
			Port:                 aws.ToInt32(db.Endpoint.Port),
			AllocatedStorage:     aws.ToInt32(db.AllocatedStorage),
			CreatedTime:          aws.ToTime(db.InstanceCreateTime),
		})
	}

	logger.Info(fmt.Sprintf("Listed %d RDS instances", len(instances)))
	return instances, nil
}

// ListLambdaFunctions lists all Lambda functions
func (s *AWSBrowserService) ListLambdaFunctions(ctx context.Context, profile, region string) ([]LambdaFunction, error) {
	if region == "" {
		region = "us-east-1"
	}

	cfg, err := s.loadAWSConfig(ctx, profile, region)
	if err != nil {
		return nil, err
	}

	client := lambda.NewFromConfig(cfg)
	result, err := client.ListFunctions(ctx, &lambda.ListFunctionsInput{})
	if err != nil {
		logger.Error("Failed to list Lambda functions", err)
		return nil, fmt.Errorf("failed to list Lambda functions: %w", err)
	}

	functions := make([]LambdaFunction, 0, len(result.Functions))
	for _, fn := range result.Functions {
		lastModified, _ := time.Parse(time.RFC3339, aws.ToString(fn.LastModified))

		functions = append(functions, LambdaFunction{
			FunctionName: aws.ToString(fn.FunctionName),
			Runtime:      string(fn.Runtime),
			Handler:      aws.ToString(fn.Handler),
			CodeSize:     fn.CodeSize,
			MemorySize:   aws.ToInt32(fn.MemorySize),
			Timeout:      aws.ToInt32(fn.Timeout),
			LastModified: lastModified,
			Description:  aws.ToString(fn.Description),
		})
	}

	logger.Info(fmt.Sprintf("Listed %d Lambda functions", len(functions)))
	return functions, nil
}
